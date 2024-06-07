apiVersion: v1
baseDomain: "{{ hostname }}"
compute:
- name: worker
  platform:
    openstack:
      zones: []
      additionalNetworkIDs: []
      type: m1.large
  replicas: 2
controlPlane:
  name: master
  platform:
    openstack:
      zones: []
      type: m1.xlarge
  replicas: 3
metadata:
  name: "ostest"
networking:
  clusterNetworks:
  - cidr: 10.128.0.0/14
    hostSubnetLength: 9
  serviceCIDR: 172.30.0.0/16
  machineCIDR: 10.196.0.0/16
  type: "{{ network_type }}"
platform:
  openstack:
    cloud:        	   "{{ cloud }}"
    externalNetwork:   "{{ external_network }}"
    region:       	   "regionOne"
    computeFlavor:     "m1.xlarge"
    lbFloatingIP: 	   "{{ api_fip }}"
    ingressFloatingIP: "{{ ingress_fip }}"
    {%- if external_dns %}
    externalDNS:
    {%- for dns in external_dns %}
    - {{ dns }}
    {%- endfor %}
    {%- endif %}
    clusterOSImage:    "rhcos"
pullSecret: |
  {{ pull_secret }}
sshKey: |
  {{ ssh_key }}
