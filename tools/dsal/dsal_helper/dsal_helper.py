# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import os
import pathlib
import socket
import subprocess
import sys

import jinja2
import netaddr
import openstack

DEV_INSTALL_REPO = 'https://github.com/shiftstack/dev-install.git'


class DSALHelper(object):
    def __init__(self):
        self.app_dir = os.path.dirname(os.path.realpath(__file__))

        parser = self._get_arg_parser()
        args = parser.parse_args()
        self._prepare_jinja()
        if hasattr(args, 'func'):
            try:
                self._setup_openstack(args.cloud)
            except:
                pass
            args.func(args)
            return

        parser.print_help()
        parser.exit()

    def _prepare_jinja(self):
        self.jinja = jinja2.Environment(
            loader=jinja2.FileSystemLoader("templates"))

    def _get_arg_parser(self):
        parser = argparse.ArgumentParser(
            description="Helper for deploying dev-install on DSAL boxes")
        parser.add_argument('-c', '--cloud',
                            default=os.environ.get('OS_CLOUD'),
                            help='name in clouds.yaml to use')

        subparsers = parser.add_subparsers(help='supported commands')

        anaconda_cfg = subparsers.add_parser(
            'anaconda-cfg', help='prepare anaconda-ks.cfg for the host')
        anaconda_cfg.add_argument('hostname', help='full hostname of DSAL box')
        anaconda_cfg.add_argument('template', help='template to use, there are'
                                                   ' no predefined ones as '
                                                   'every machine has its own '
                                                   'specifics')
        anaconda_cfg.add_argument('--disks',
                                  help='comma-separated list of disks to use',
                                  default='sda,sdb,sdc')
        anaconda_cfg.add_argument('--boot-disk', help='boot disk to use',
                                  default='sda')
        anaconda_cfg.set_defaults(func=self.anaconda_cfg)

        dev_install_cfg = subparsers.add_parser(
            'dev-install-cfg', help='clone and prepare dev-install for the '
                                    'host')
        dev_install_cfg.add_argument('hostname',
                                     help='full hostname of DSAL box')
        dev_install_cfg.add_argument('--host-ip',
                                     help='IP of the host, if not set will '
                                          'attempt to autodetect',
                                     default=None)
        dev_install_cfg.add_argument('--fip-pool-start', required=True,
                                     help='first IP of the FIP pool assigned '
                                          'to the hostname')
        dev_install_cfg.add_argument('--fip-pool-end', required=True,
                                     help='last IP of the FIP pool assigned '
                                          'to the hostname')
        # TODO(dulek): ceph-disk could accept a list
        dev_install_cfg.add_argument('--ceph-disk', required=True,
                                     help='disk that CEPH should use, point '
                                          'to SSDs RAID here. E.g. /dev/sdc')
        dev_install_cfg.set_defaults(func=self.dev_install_cfg)

        openshift_install_cfg = subparsers.add_parser(
            'openshift-install-cfg', help='creates FIPs and prepares '
                                          'install-config.yaml for the host')
        openshift_install_cfg.add_argument('hostname',
                                           help='full hostname of DSAL box')
        openshift_install_cfg.add_argument('--network-type',
                                           help='networkType to set, defaults '
                                                'to Kuryr', default='Kuryr')
        openshift_install_cfg.add_argument('--pull-secret', required=True,
                                           help='path to pull secret file')
        openshift_install_cfg.add_argument('--ssh-key',
                                           help='path to public SSH key,'
                                                'defaults to '
                                                '~/.ssh/id_rsa.pub',
                                           default=os.path.expanduser(
                                               '~/.ssh/id_rsa.pub'))
        openshift_install_cfg.add_argument('--external-network',
                                           help='external network to use for '
                                                'FIPs, defaults to "external"',
                                           default='external')
        openshift_install_cfg.add_argument('--api-fip',
                                           help='FIP to use for API, if not '
                                                'set will try to find or '
                                                'create one')
        openshift_install_cfg.add_argument('--ingress-fip',
                                           help='FIP to use for ingress, if '
                                                'not set will try to find or '
                                                'create one')
        openshift_install_cfg.set_defaults(func=self.openshift_install_cfg)

        return parser

    def _setup_openstack(self, cloud_name):
        conn = openstack.connection.from_config(cloud=cloud_name)
        self.os = conn
        self.neutron = conn.network

    def _create_dir(self, directory):
        pathlib.Path(directory).mkdir(exist_ok=True, parents=True)

    def _render(self, directory, template_file, file, vars):
        self._create_dir(directory)
        template = self.jinja.get_template(template_file)
        with open(f'{directory}/{file}', 'w') as f:
            print(template.render(**vars), file=f)

    def anaconda_cfg(self, args):
        self._render('anaconda', args.template,
                     f'anaconda-ks-{args.hostname}.cfg', args.__dict__)

    def dev_install_cfg(self, args):
        vars = args.__dict__
        if args.host_ip is None:
            vars['host_ip'] = socket.gethostbyname(args.hostname)

        range = netaddr.IPRange(args.fip_pool_start, args.fip_pool_end)
        vars['control_plane_ip'] = range[0]
        vars['external_start'] = range[1]
        vars['external_end'] = range[-1]

        self._create_dir('dev-install')
        if not os.path.exists(f'dev-install/{args.hostname}'):
            subprocess.run(['git', 'clone', DEV_INSTALL_REPO,
                            f'dev-install/{args.hostname}'],
                           stdin=sys.stdin, stdout=sys.stdout)

        # TODO(dulek): Choose template based on OSP version.
        self._render('dev-install', 'local-overrides-16.2.yaml.tpl',
                     f'{args.hostname}/local-overrides.yaml', vars)

        subprocess.run(['make', 'config', f'host={args.hostname}',
                        'user=stack'], cwd=f'dev-install/{args.hostname}',
                       stdin=sys.stdin, stdout=sys.stdout)

    def openshift_install_cfg(self, args):
        vars = args.__dict__
        for key in ('pull_secret', 'ssh_key'):
            with open(vars[key], 'r') as f:
                content = f.read()
            vars[key] = content.strip()

        fips = self.neutron.ips(port_id=None)
        for key in ('api_fip', 'ingress_fip'):
            if not vars[key]:
                # First try finding a free one.
                try:
                    vars[key] = next(fips).floating_ip_address
                except StopIteration:
                    pass
            if not vars[key]:
                # Then try creating one.
                network = self.neutron.find_network(args.external_network)
                vars[key] = self.neutron.create_ip(
                    floating_network_id=network.id).floating_ip_address

        self._render(f'install-config/{args.hostname}',
                     'install-config.yaml.tpl',
                     f'install-config.yaml', vars)

        hosts = f"{vars['api_fip']} api.ostest.{args.hostname}\n" \
                f"{vars['ingress_fip']} *.apps.ostest.{args.hostname}\n" \
                f"{vars['ingress_fip']} console-openshift-console.apps." \
                f"ostest.{args.hostname}\n" \
                f"{vars['ingress_fip']} integrated-oauth-server-openshift-" \
                f"authentication.apps.ostest.{args.hostname}\n" \
                f"{vars['ingress_fip']} oauth-openshift.apps.ostest." \
                f"{args.hostname}\n"

        # TODO(dulek): Save it automatically?
        print('Put this in /etc/hosts:')
        print(hosts)


def main():
    DSALHelper()


if __name__ == '__main__':
    DSALHelper()
