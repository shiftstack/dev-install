#!/bin/bash -x

ports=`openstack port list --device-owner "trunk:subport" -f value | grep DOWN | cut -d " " -f 1`
trunks=`openstack network trunk list -f value -c ID`

for port in $ports; do
    for trunk in $trunks; do
        vlan_id=`openstack network subport list --trunk $trunk -f value | grep $port | cut -d " " -f 3`
        if [[ $vlan_id ]]; then
            # Found it!
            echo "Port $port is in trunk $trunk with VLAN ID $vlan_id"
            openstack network trunk unset --subport $port $trunk
            openstack network trunk set --subport port=$port,segmentation-type=vlan,segmentation-id=$vlan_id $trunk
            break
        fi
    done
done
