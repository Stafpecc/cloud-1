.SILENT:

PURPLE  := \033[1;35m
GREEN   := \033[1;32m
RED     := \033[1;31m
YELLOW  := \033[1;33m
CYAN    := \033[1;36m
RESET   := \033[0m

VAGRANT   := vagrant
ANSIBLE   := ansible
PLAYBOOK  := ansible-playbook
INVENTORY := inventory/hosts.yml
SITE      := playbook.yml
VAULT     := group_vars/all/vault.yml
LIMIT     ?= all
VM        ?= srv1

.PHONY: all
all: up

# Vagrant

.PHONY: up
up:
	echo "$(GREEN)Starting VMs...$(RESET)"
	$(VAGRANT) up

.PHONY: stop
stop:
	echo "$(YELLOW)Stopping VMs...$(RESET)"
	$(VAGRANT) halt

.PHONY: reload
reload:
	echo "$(YELLOW)Rebooting VMs (reboot test)...$(RESET)"
	$(VAGRANT) reload

.PHONY: clean
clean:
	echo "$(RED)Destroying VMs...$(RESET)"
	$(VAGRANT) destroy -f

.PHONY: re
re: clean up

.PHONY: status
status:
	echo "$(CYAN)VM status:$(RESET)"
	$(VAGRANT) status

.PHONY: ssh
ssh:
	echo "$(CYAN)Connecting to $(VM)...$(RESET)"
	$(VAGRANT) ssh $(VM)

# Ansible

.PHONY: ping
ping:
	echo "$(CYAN)Ansible ping...$(RESET)"
	$(ANSIBLE) -i $(INVENTORY) $(LIMIT) -m ping

.PHONY: syntax
syntax:
	echo "$(CYAN)Checking playbook syntax...$(RESET)"
	$(PLAYBOOK) -i $(INVENTORY) $(SITE) --syntax-check

.PHONY: lint
lint:
	echo "$(CYAN)Running ansible-lint...$(RESET)"
	ansible-lint $(SITE)

.PHONY: deploy
deploy:
	echo "$(GREEN)Deploying on $(LIMIT)...$(RESET)"
	$(PLAYBOOK) -i $(INVENTORY) $(SITE) --limit $(LIMIT) --ask-vault-pass

.PHONY: check
check:
	echo "$(YELLOW)Dry run (--check --diff)...$(RESET)"
	$(PLAYBOOK) -i $(INVENTORY) $(SITE) --limit $(LIMIT) --check --diff --ask-vault-pass

.PHONY: idempotence
idempotence:
	echo "$(YELLOW)Running the playbook twice, 2nd run must show changed=0...$(RESET)"
	$(PLAYBOOK) -i $(INVENTORY) $(SITE) --limit $(LIMIT) --ask-vault-pass > /dev/null
	$(PLAYBOOK) -i $(INVENTORY) $(SITE) --limit $(LIMIT) --ask-vault-pass | tee /tmp/cloud1_idem.log
	if grep -E "changed=[1-9]" /tmp/cloud1_idem.log > /dev/null; then \
		echo "$(RED)NOT idempotent$(RESET)"; exit 1; \
	else \
		echo "$(GREEN)Idempotent$(RESET)"; \
	fi

.PHONY: vault-edit
vault-edit:
	ansible-vault edit $(VAULT)

.PHONY: vault-create
vault-create:
	ansible-vault create $(VAULT)

# Fclean

.PHONY: fclean
fclean: destroy
	echo "$(RED)Removing .vagrant cache...$(RESET)"
	rm -rf .vagrant
