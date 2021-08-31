apiVersion: v1
baseDomain: "{{ hostname }}"
compute:
- name: worker
  platform:
    openstack:
      zones: []
      additionalNetworkIDs: []
  replicas: 3
controlPlane:
  name: master
  platform:
    openstack:
      zones: []
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
    externalNetwork:   "external"
    region:       	   "regionOne"
    computeFlavor:	   "m1.xlarge"
    lbFloatingIP: 	   "{{ api_fip }}"
    ingressFloatingIP: "{{ ingress_fip }}"
    externalDNS:  	   ["1.1.1.1"]
    clusterOSImage:    "rhcos"
pullSecret: |
  {{ pull_secret }}
sshKey: |
  {{ ssh_key }}
