# The installation target used when initializing the local ansible inventory.
# N.B. This is *only* used when initializing the local ansible inventory file.
#      Specifically it is not used if the inventory file already exists.
#
# It is recommended to run:
#   make config host=<myhost>
host ?= my_osp_host
ansible_args ?=

ANSIBLE_CMD=ANSIBLE_FORCE_COLOR=true ansible-playbook $(ansible_args) -i inventory -e @local-overrides.yaml

#
# Targets which initialize local state
#

.PHONY: config
config: inventory local-overrides.yaml

inventory:
	echo -e "all:\n  hosts:\n    standalone:\n      ansible_host: $(host)\n" > $@

local-overrides.yaml:
	echo -e "# Override default variables by putting them in this file\ncloudname: standalone\nstandalone_host: $(host)" > $@


#
# Deploy targets
#

.PHONY: prepare_host
prepare_host: inventory local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/prepare_host.yaml

.PHONY: install_stack
install_stack: inventory local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/install_stack.yaml

.PHONY: local_os_client
local_os_client: inventory local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/local_os_client.yaml

.PHONY: prepare_stack
prepare_stack: inventory local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/prepare_stack.yaml

.PHONY: destroy
destroy: inventory local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/destroy.yaml
