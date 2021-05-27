# dev-install

dev-install installs [TripleO standalone](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/standalone.html) on a remote system for development use.

## Host configuration

dev-install requires that:
* an appropriate OS has already been installed
* the machine running dev-install can SSH to the standalone host as either root or a user with passwordless sudo access

For OSP 16.2, the recommended OS is RHEL 8.4. For OSP 17, the recommended RHEL is 8.4 (it will not work on <8.3).
There is no need to do any other configuration prior to running dev-install.
When deploying on CentOS, you need to check what platform is supported for the TripleO version that you plan to deploy.

## Local pre-requisites

dev-install requires up to date versions of `ansible` and `make`, both of which must be installed manually before invoking dev-install.

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

This section contains configuration procedures for single root input/output virtualization (SR-IOV) and
dataplane development kit (DPDK) for network functions virtualization infrastructure (NFVi) in 
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

DPDK Variables
--------------

Please read the [official manual](https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html-single/network_functions_virtualization_planning_and_configuration_guide/index#concept_ovsdpdk-cpu-parameters)
to understand better about the following parameters, they'll help you to figure out what values can be set, which
couldn't be automatically set for you by dev-install.

| Name              | Default Value       | Description          |
|-------------------|---------------------|----------------------|
| `dpdk_kernel_args` | `[undefined]` | Kernel arguments to configure when booting the machine. |
| `dpdk_isol_cpus_list` | `[undefined]` | A set of CPU cores isolated from the host processes represented via a comma-separated list or range of physical host CPU numbers to which processes for pinned instance CPUs can be scheduled.
| `dpdk_cpu_shared_set` | `[undefined]` | A comma-separated list or range of physical host CPU numbers used to determine the host CPUs for instance emulator threads.

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
