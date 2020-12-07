# The installation target used when initializing the local ansible inventory.
# N.B. This is *only* used when initializing the local ansible inventory file.
#      Specifically it is not used if the inventory file already exists.
#
# It is recommended to run:
#   make config host=<myhost>
host ?= my_osp_host
ansible_args ?=

ANSIBLE_CMD=ANSIBLE_FORCE_COLOR=true ansible-playbook $(ansible_args) -i inventory -e @local-overrides.yaml

usage:
	@echo 'Usage:'
	@echo
	@echo 'make config host=<standalone host>'
	@echo 'make osp_full'
	@echo
	@echo 'Individual install phase targets:'
	@echo '  prepare_host: Host configuration required before installing standalone, including rhos-release'
	@echo '  install_stack: Install TripleO standalone'
	@echo '  prepare_stack: Configure defaults in OSP and create shiftstack user'
	@echo
	@echo 'Utility targets:'
	@echo '  local_os_client: Configure local clouds.yaml to use standalone cloud'

#
# Targets which initialize local state
#

.PHONY: config
config: inventory local-overrides.yaml

inventory:
	echo -e "all:\n  hosts:\n    standalone:\n      ansible_host: $(host)\n      ansible_user: root\n" > $@

local-overrides.yaml:
	echo -e "# Override default variables by putting them in this file\ncloudname: standalone\nstandalone_host: $(host)" > $@


#
# Deploy targets
#

.PHONY: osp_full
osp_full: prepare_host install_stack prepare_stack

.PHONY: prepare_host
prepare_host: inventory local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/prepare_host.yaml

.PHONY: install_stack
install_stack: inventory local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/install_stack.yaml

.PHONY: prepare_stack
prepare_stack: inventory local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/prepare_stack.yaml

.PHONY: local_os_client
local_os_client: inventory local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/local_os_client.yaml

.PHONY: destroy
destroy: inventory local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/destroy.yaml
