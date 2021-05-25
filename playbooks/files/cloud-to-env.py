#!/usr/bin/python3

import itertools
import json
import os
import yaml

def cloud_to_env(d):
    return itertools.chain.from_iterable(
            cloud_to_env(v) if isinstance(v, dict)
            else (("OS_%s" % k.upper(), v),)
            for k, v in d.items())

with open("%s/.config/openstack/clouds.yaml" % os.environ['HOME']) as f:
    clouds = yaml.safe_load(f)

os_cloud=os.environ['OS_CLOUD']
cloud=clouds['clouds'][os_cloud]
env_vars=dict(cloud_to_env(cloud))
print(json.dumps(env_vars))
