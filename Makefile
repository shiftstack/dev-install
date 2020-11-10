# The installation target used when initializing the local ansible inventory.
# N.B. This is *only* used when initializing the local ansible inventory file.
#      Specifically it is not used if the inventory file already exists.
host ?= my_osp_host

ANSIBLE_CMD=ANSIBLE_FORCE_COLOR=true ansible-playbook -i inventory -e @local-overrides.yaml

#
# Targets which initialize local state
#

inventory:
	echo -e "all:\n  hosts:\n    standalone:\n      ansible_host: $(host)" > $@

local-overrides.yaml:
	echo -e "# Override default variables by putting them in this file\ncloudname: standalone" > $@


#
# Deploy targets
#

.PHONY: prepare_host
prepare_host: inventory local-overrides.yaml
	$(ANSIBLE_CMD) prepare_host.yaml

.PHONY: install_stack
install_stack: inventory local-overrides.yaml
	$(ANSIBLE_CMD) install_stack.yaml

.PHONY: local_os_client
local_os_client: inventory local-overrides.yaml
	$(ANSIBLE_CMD) local_os_client.yaml

.PHONY: destroy
destroy: inventory local-overrides.yaml
	$(ANSIBLE_CMD) destroy.yaml
