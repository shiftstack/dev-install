
host ?= osp


inventory:
	echo -e "[standalone]\n$(host)" > $@

local-overrides.yaml:
	echo -e "# Override default variables by putting them in this file\nfoo:" > $@

prepare_host: inventory local-overrides.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i inventory -e @local-overrides.yaml \
	prepare_host.yaml

install_stack: inventory local-overrides.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i inventory -e @local-overrides.yaml \
	install_stack.yaml

destroy: inventory local-overrides.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i inventory -e @local-overrides.yaml \
	destroy.yaml
