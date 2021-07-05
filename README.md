# dev-install

dev-install installs [TripleO standalone](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/standalone.html) on a remote system for development use.

## Host configuration

dev-install requires that:
* an appropriate OS has already been installed
* the machine running dev-install can SSH to the standalone host as either root or a user with passwordless sudo access
* this machine has Ansible installed, and some dependencies like python3-netaddr.

For OSP 16.2, the recommended OS is RHEL 8.4. For OSP 17, the recommended RHEL is 8.4 (it will not work on <8.3).
There is no need to do any other configuration prior to running dev-install.
When deploying on TripleO from upstream, you need to deploy on CentOS Stream. If CentOS is not Stream, dev-install will migrate it.

## Local pre-requisites

dev-install requires up to date versions of `ansible` and `make`, both of which must be installed manually before invoking dev-install.

If installing OSP 16.1 with official rhel 8.2 cloud images, it is required that the cloud-init service be disabled before deployment as per [THIS](https://review.opendev.org/c/openstack/tripleo-heat-templates/+/764933)

At present the deployment depends on a valid DHCP source for the external interface (br-ex) as per [THIS](https://github.com/shiftstack/dev-install/blob/main/playbooks/templates/dev-install_net_config.yaml.j2#L9)

All other requirements should be configured automatically by ansible. Note that dev-install doesn't require root access on the machine it is invoked from, only the target host.

## Running dev-install

dev-install is invoked using its Makefile. The simplest invocation is:

```
$ make config host=<standalone host>
$ make osp_full
```

`make config` initialises 2 local statefiles:
* `inventory` - this is an ansible inventory file, initialised such that `standalone` is an alias for your target host.
* `local-overrides.yaml` - this is an ansible vars file containing configuration which overrides the defaults in `playbooks/vars/defaults.yaml`.

Both of these files can be safely modified.

`make osp_full` performs the actual installation. On an example system with 12 cores and 192GB RAM and running in a Red Hat data centre this takes approximately 65 minutes to execute.

If you deal with multiple OpenStack clouds and want to maintain a single local-overrides per cloud, you can create `local-overrides-<name>.yaml`
and then use it when deploying with `make osp_full overrides=local-overrides-<name>.yaml`

## Accessing OpenStack from your workstation

By default, dev-install configures OpenStack to use the default public IP of the
host. To access this you just need a correct clouds.yaml, which dev-install
configures with:

```
make local_os_client
```

This will configure your local clouds.yaml with 2 entries:
* `standalone` - The admin user
* `standalone_openshift` - The appropriately configured non-admin openshift user

You can change the name of these entries by editing `local-overrides.yaml` and
setting `local_cloudname` to something else.

## Network configuration

dev-install will create a new OVS bridge called br-ex and move the host's
external interface on to that bridge. This bridge is used to provide the
`external` provider network if `external_fip_pool_start` and
`external_fip_pool_end` are defined in `local-overrides.yaml`.

In addition it will create OVS bridges called br-ctlplane and br-hostonly. The
former is used internally by OSP. The latter is a second provider network which
is only routable from the host.

Note that we don't enable DHCP on provider networks by default, and it is not
recommended to enable DHCP on the external network at all. To enable DHCP on the
hostonly network after installation, run:

```
OS_CLOUD=standalone openstack subnet set --dhcp hostonly-subnet
```

`make local_os_client` will write a
[sshuttle](https://github.com/sshuttle/sshuttle) script to
`scripts/sshuttle-standalone.sh` which will route to the hostonly provider
network over ssh.

## Configuration

dev-install is configured by overriding variables in `local-overrides.yaml`. See
the [default variable
definitions](https://github.com/shiftstack/dev-install/blob/master/playbooks/vars/defaults.yaml)
for what can be overridden.

## Sizing

When idle, a standalone deployment uses approximately:
* 16GB RAM
* 15G on /
* 3.5G on /home
* 3.6G on /var/lib/cinder
* 3.6G on /var/lib/nova

There is no need to mount /var/lib/cinder and /var/lib/nova separately if / is large enough for your workload.

## Advanced features

### NFV enablement

This section contains configuration procedures for single root input/output virtualization (SR-IOV)
for network functions virtualization infrastructure (NFVi) in 
your Standalone OpenStack deployment. 
Unfortunately, most of these parameters don't have default values nor can be automatically figured out in
a Standalone type environment.

SR-IOV Variables
----------------

To understand how the SR-IOV configuration works, please have a look at this [upstream guide](https://docs.openstack.org/neutron/latest/admin/config-sriov.html).

| Name              | Default Value       | Description          |
|-------------------|---------------------|----------------------|
| `sriov_services` | `['OS::TripleO::Services::NeutronSriovAgent', 'OS::TripleO::Services::BootParams']` | List of TripleO services to add to the default Standalone role |
| `sriov_interface` | `[undefined]` | Name of the SR-IOV capable interface. Must be enabled in BIOS. e.g. `ens1f0` |
| `sriov_nic_numvfs` | `[undefined]` | Number of Virtual Functions that the NIC can handle. |
| `sriov_nova_pci_passthrough` | `[undefined]` | List of PCI Passthrough whitelist parameters. [Guidelines](https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html/configuring_the_compute_service_for_instance_creation/configuring-pci-passthrough#guidelines-for-configuring-novapcipassthrough-osp) to configure it. |

Kernel Variables
----------------

It is possible to configure the Kernel to boot with specific arguments:

| Name              | Default Value       | Description          |
|-------------------|---------------------|----------------------|
| `kernel_services` | `['TripleO::Services::BootParams']` | List of TripleO services to add to the default Standalone role |
| `kernel_args` | `[undefined]` | Kernel arguments to configure when booting the machine. |

### SSL for public endpoints

This sections contains configuration procedures for enabling SSL on OpenStack public endpoints.

| Name              | Default Value       | Description          |
|-------------------|---------------------|----------------------|
| `ssl_enabled` | `false` | Whether or not we enable SSL for public endpoints |
| `ssl_ca_cert` | `[undefined]` | CA certificate. If undefined, a self-signed will be generated and deployed |
| `ssl_ca_key` | `[undefined]` | CA key. If undefined, it will be generated and used to sign the SSL certificate |
| `ssl_key` | `[undefined]` | SSL Key. If undefined, it will be generated and deployed |
| `ssl_cert` | `[undefined]` | SSL certificate. If undefined, a self-signed will be generated and deployed |
| `ssl_ca_cert_path` | `/etc/pki/ca-trust/source/anchors/simpleca.crt` | Path to the CA certificate |
| `update_local_pki` | `false` | Whether or not we want to update the local PKI with the CA certificate |

### Multi-node deployments

It is possible to deploy Edge-style environments, where multiple AZ are configured.

#### Deploy the Central site

Deploy a regular cloud with dev-install, and make sure you set `dcn_az` parameter to `central`.
Once this is done, you need to collect the content from `/home/stack/exported-data` into a local directory
on the host where dev-install is executed.

#### Deploy the "AZ" sites

Before deploying OSP, you need to scp the content from `exported-data` into the remote hosts into
`/opt/exported-data`.
Once this is done, you can deploy the AZ sites with a regular config for dev-install, except that you'll need to set
these parameters:

* `dcn_az`: must contains "az" in the string (e.g. az0, az1)
* `local_ip`: choose an available IP in the control plane subnet, (e.g. 192.168.24.10)
* `control_plane_ip`: same as for `local_ip`, pick one that is available (e.g. 192.168.24.11)
* `hostonly_gateway`: if using provider networks, you'll need to select an available IP (e.g. 192.168.25.2)
* `tunnel_remote_ips`: the list of known public IPs that will be used to establish the VXLAN tunnels.

Notes:

* The control plane bridges will be connected thanks to VXLAN tunnels, which is why we need to select control plane IP for AZ nodes that were not taken on the Central site.
* If you deploy the clouds in OpenStack, you need to make sure that the security groups allow VXLAN (udp/4789).
* If the public IPs aren't predictable, you'll need to manually change the MTU on the br-ctlplane and br-hostonly on the central
  site and the AZ sites where needed. You can do it by editing the os-net-config configuration file and run os-net-config to apply
  it.

#### Post Deployment Stack Updates

It is possible to perform stack updates on an ephemeral standalone stack.

Copying the generated tripleo_deploy.sh in your deployment users folder (eg. /home/stack/tripleo_deploy.sh) to tripleo_update.sh and add the parameter --force-stack-update.  This will allow you to modify the stack configuration without needing to redeploy the entire cloud which can save you considerable time.


