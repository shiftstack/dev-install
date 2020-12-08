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

## Configuring access to OpenStack from your workstation

To access OpenStack on your standalone host from your workstation you need 2 things:
* A route to the virtual network on the standalone host
* A correct clouds.yaml

dev-install configures both of these with:

```
make local_os_client
```

This will configure your local clouds.yaml with 2 entries:
* `standalone` - The admin user
* `standalone_openshift` - The appropriately configured non-admin openshift user

You can change the name of these entries by editing `local-overrides.yaml` and setting `cloudname` to something else.

We use [sshuttle](https://github.com/sshuttle/sshuttle) to provide remote access. `make local_os_client` writes a script to `scripts/sshuttle-standalone.sh` in the dev-install directory with appropriate arguments.

## Network configuration

dev-install doesn't touch any of the network interfaces on the standalone host. Instead it creates a dummy interface called `dummy0` which is used by the standalone host. External connectivity is automatically configured for OpenStack using the physical interface.

## Sizing

When idle, OSP17 standalone on RHEL8 uses approximately:
* 16GB RAM
* 15G on /
* 3.5G on /home
* 3.6G on /var/lib/cinder
* 3.6G on /var/lib/nova

There is no need to mount /var/lib/cinder and /var/lib/nova separately if / is large enough for your workload.
