# The installation target used when initializing the local ansible inventory.
# N.B. This is *only* used when initializing the local ansible inventory file.
#      Specifically it is not used if the inventory file already exists.
#
# It is recommended to run:
#   make config host=<myhost>
host ?= my_osp_host
user ?= root
ansible_args ?=

ANSIBLE_CMD=ANSIBLE_FORCE_COLOR=true ansible-playbook $(ansible_args) -i inventory.yaml -e @local-overrides.yaml

usage:
	@echo 'Usage:'
	@echo
	@echo 'make config host=<standalone host>'
	@echo 'make osp_full'
	@echo
	@echo 'Individual install phase targets:'
	@echo '  local_requirements: Install Ansible requirements required to run dev-install'
	@echo '  prepare_host: Host configuration required before installing standalone, including rhos-release'
	@echo '  network: Host networking configuration required before installing standalone'
	@echo '  install_stack: Install TripleO standalone'
	@echo '  prepare_stack: Configure defaults in OSP and create shiftstack user'
	@echo
	@echo 'Utility targets:'
	@echo '  local_os_client: Configure local clouds.yaml to use standalone cloud'
	@echo '  prepare_stack_testconfig: Download cirros image and create a test network, router and security group'

#
# Targets which initialize local state
#

.PHONY: config
config: inventory.yaml local-overrides.yaml

inventory.yaml:
	echo -e "all:\n  hosts:\n    standalone:\n      ansible_host: $(host)\n      ansible_user: $(user)\n" > $@

local-overrides.yaml:
	echo -e "# Override default variables by putting them in this file\nstandalone_host: $(host)" > $@


#
# Deploy targets
#

.PHONY: osp_full
osp_full: local_requirements prepare_host network install_stack prepare_stack

.PHONY: local_requirements
local_requirements: inventory.yaml local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/local_requirements.yaml

.PHONY: prepare_host
prepare_host: inventory.yaml local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/prepare_host.yaml

.PHONY: network
network: inventory.yaml local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/network.yaml

.PHONY: install_stack
install_stack: inventory.yaml local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/install_stack.yaml

.PHONY: prepare_stack
prepare_stack: inventory.yaml local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/prepare_stack.yaml

.PHONY: prepare_stack_testconfig
prepare_stack_testconfig: inventory.yaml local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/prepare_stack_testconfig.yaml

.PHONY: local_os_client
local_os_client: inventory.yaml local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/local_os_client.yaml

.PHONY: certs
certs: local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/certs.yaml

.PHONY: destroy
destroy: inventory.yaml local-overrides.yaml
	$(ANSIBLE_CMD) playbooks/destroy.yaml
