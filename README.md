# dev-install

dev-install installs [TripleO standalone](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/standalone.html) on a remote system for development use.

## Host configuration

dev-install requires that:
* an appropriate OS has already been installed
* the machine running dev-install can SSH to the standalone host as either root or a user with passwordless sudo access

For OSP 16 and 17, the recommended OS is RHEL 8.2. There is no need to do any other configuration prior to running dev-install.

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

When idle, OSP17 standalone on RHEL8 uses approximately:
* 16GB RAM
* 15G on /
* 3.5G on /home
* 3.6G on /var/lib/cinder
* 3.6G on /var/lib/nova

There is no need to mount /var/lib/cinder and /var/lib/nova separately if / is large enough for your workload.
