#!/bin/bash -x

sgs=`openstack security group list -f value | grep OpenShift | cut -f 1 -d " "`

for sg in $sgs; do
    openstack security group rule create --dst-port 22 --protocol tcp $sg
done
