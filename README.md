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

You can change the name of these entries by editing `local-overrides.yaml` and
setting `local_cloudname` to something else.

## Network configuration

dev-install will create a new OVS bridge called br-ex and move your external
interface on to that bridge. It will also create a new interface called dummy0
which will be added to the br-ctlplane bridge when it is created by TripleO.
From here there are 2 network configuration options.

### Internal-only networking (default)

With no further configuration, dev-install will configure the `public` provider
network on br-ctlplane with subnet 192.168.25.0/24. The OSP public endpoint will
use 192.168.25.1.

For remote access to this network you can use
[sshuttle](https://github.com/sshuttle/sshuttle). `make local_os_client` writes
a script to `scripts/sshuttle-standalone.sh` in the dev-install directory with
appropriate arguments.

### Externally routable public network

This is the best configuration when you can route multiple IP addresses to the
external interface of your host, for example a lab system where you control the
whole subnet, or a DSAL system where you requested additional FIPs.

dev-install will create the `public` provider network on br-ex, bridged to your
external nic. You need to override several parameters in local-overrides.yaml to
provide your networking details. For example, on my DSAL system I have:

```
public_cidr: 10.46.26.0/23
public_api: 10.46.27.66
public_gateway: 10.46.27.254
public_fip_pool_start: 10.46.27.67
public_fip_pool_end: 10.46.27.75
public_uses_external_nic: true
```

In this case, my external NIC is on the subnet `10.46.26.0/23`. The host has a
primary IP in that range, and the default gateway for the subnet is
`10.46.27.254`.

In addition, I have an allocation of 10 FIPs in the range
`10.46.27.66`-`10.46.27.75` (NOTE: these are also in the same subnet). I have
used the first of these, `10.46.27.66` as OSP's public API endpoint. The rest
will be used as the allocation pool of OSP's public provider network. That is,
floating IPs allocated by OSP are externally routable.

Finally, set `public_uses_external_nic` to tell dev-install to configure
external networking.

## Sizing

When idle, OSP17 standalone on RHEL8 uses approximately:
* 16GB RAM
* 15G on /
* 3.5G on /home
* 3.6G on /var/lib/cinder
* 3.6G on /var/lib/nova

There is no need to mount /var/lib/cinder and /var/lib/nova separately if / is large enough for your workload.
