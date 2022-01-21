# Override default variables by putting them in this file
standalone_host: {{ hostname }}
public_api: {{ host_ip }}
external_cidr: 10.1.8.0/22
external_gateway: 10.1.11.254
external_fip_pool_start : {{ external_start }}
external_fip_pool_end: {{ external_end }}
rhos_release: 16.2
ceph_devices:
  - {{ ceph_disk }}
