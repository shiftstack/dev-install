#!/usr/bin/env bash

# Script to execute on the central site to generate useful
# data to deploy edge sites.
# Largely inspired by https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/standalone.html#extract-deployment-information-from-the-controller-node

unset OS_CLOUD
export OS_AUTH_TYPE=none
export OS_ENDPOINT=http://127.0.0.1:8006/v1/admin
DIR=/home/stack/exported-data

mkdir -p $DIR
openstack stack output show standalone EndpointMap --format json \
| jq '{"parameter_defaults": {"EndpointMapOverride": .output_value}}' \
> $DIR/endpoint-map.json

openstack stack output show standalone HostsEntry --format json \
| jq -r '{"parameter_defaults":{"ExtraHostFileEntries": .output_value}}' \
> $DIR/extra-host-file-entries.json

cat <<EOF > $DIR/oslo.yaml
parameter_defaults:
  StandaloneExtraConfig:
    oslo_messaging_notify_use_ssl: false
    oslo_messaging_rpc_use_ssl: false
EOF
sudo egrep "oslo.*password" /etc/puppet/hieradata/service_configs.json \
| sed -e s/\"//g -e s/,//g >> $DIR/oslo.yaml

STANDALONE_LATEST=$(find $HOME/standalone-ansible-*/group_vars -type d -printf "%T@ %p\n" | sort -n | cut -d' ' -f 2- | tail -n 1)
python3 -c "import json; t = {'parameter_defaults': {'AllNodesExtraMapData': json.loads(open('$STANDALONE_LATEST/overcloud.json').read()) }}; print(t)" > $DIR/all-nodes-extra-map-data.json

cp $HOME/tripleo-standalone-passwords.yaml $DIR/passwords.yaml
sudo chmod 755 $DIR/passwords.yaml
