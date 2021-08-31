#!/bin/bash -x

host=$1

echo "Reprovisioning system"
bkr system-provision --kickstart anaconda/anaconda-ks-${host}.cfg --distro-tree 118371 --kernel-options "console=tty0 console=ttyS1,115200n81" $host

echo "Waiting for SSH to succeed"
until ssh root@${host} echo "I\'m in"; do
    sleep 30
done
echo "SSH succeeded!"

cd dev-install/$host
make osp_full
make local_os_client
