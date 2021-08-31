# DSAL tools

Tool box helping with provisioning fresh DSAL boxes. It aims at providing full
management of configurations required to configure the boxes.

## dsal_helper.py

Utility producing useful configs that can be used to provision nodes.

To use it you need to install it:
```
cd tools/dsal
$ pip install .
```

(You may need to add ~/.local/bin to PATH)

### Generating anaconda-ks.cfg

```
dsal-helper anaconda-cfg --disks sda,sdb --boot-disk sda <hostname>
```

The file will get created as `anaconda/anaconda-ks-<hostname>`.

### Cloning and configuring dev-install

```
dsal-helper dev-install-cfg --fip-pool-start 10.1.10.51 --fip-pool-end 10.1.10.55 --ceph-disk /dev/sdb <hostname>
```

The dev-install will be cloned into `dev-install/<hostname>` and be ready to
run `make osp_full` there. The configuration will use first FIP as an OpenStack
VIP.

### Generating install-config.yaml

```
dsal-helper openshift-install-cfg --pull-secret ../pull-secret.yaml --ssh-key ~/.ssh/id_rsa.pub <hostname>
```

Script will attempt to find free FIPs to use and create new ones if there are
none. The `install-config.yaml` will be created in
`install-config/<hostname>/install-config.yaml` so you can immediately use that
directory as `--dir` of `openshift-install`. `networkType` defaults to Kuryr, 
use `--network-type` to change that.

The command will print `/etc/hosts` entries required to access the cluster.

## Scripts

There are few useful scripts in `scripts` folder.

### open-ssh.sh

This will look up OpenShift master and workers SGs and add rules allowing SSH
traffic to the VMs.

### fix-down-ports.sh

This attempts to reattach subports in DOWN status to the trunks in order to fix
them, so they become ACTIVE. Useful for Kuryr deployments on faulty OSPs.

### get-latest.sh <version>

This will look up and download latest openshift-install for a given version in
form of `4.x`, e.g. `get-latest.sh 4.9`. The binary will be placed in a
directory named with the nightly version.

## TODOs
* Supporting anything else than 8.4 and 16.2.
* Automating other useful activities:
  * Downloading openshift-install.
  * Managing clouds.yaml correctly when using multiple boxes.
  * Setting KUBECONFIG.
  * Managing /etc/hosts automatically.