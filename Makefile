# Makefile for Docker container management
# Usage: make run-container IMAGE=your_image_name [CONTAINER_NAME=your_container_name]

# Default target - run exec
.DEFAULT_GOAL := exec

.PHONY: run-container update rm-container exec secret-file

# Set default container name if not provided
CONTAINER_NAME ?= buildtmp

# Set default shell if not provided
SPECIFIC_SHELL ?= bash

# Set default secret file path
SECRET_FILE ?= .secret

# Update target - runs update.sh script if it exists
update:
	@if [ -f update.sh ]; then \
		echo "Running update.sh..."; \
		./update.sh; \
	else \
		echo "update.sh not found, skipping..."; \
	fi

# Run container target - depends on update and requires IMAGE parameter
run-container: update
ifndef IMAGE
	@echo "Error: IMAGE parameter is required"
	@echo "Usage: make run-container IMAGE=your_image_name [CONTAINER_NAME=your_container_name]"
	@exit 1
endif
	docker run -itd --name $(CONTAINER_NAME) -v `pwd`:/root/ -u `id -u`:`id -g` $(IMAGE)
	docker exec -u 0 $(CONTAINER_NAME) useradd -u `id -u` --groups wheel -m `whoami`
	docker exec -u 0 $(CONTAINER_NAME) sh -c "echo `whoami` 'ALL=(ALL) ALL' >> /etc/sudoers"
	@if [ -f "$(SECRET_FILE)" ]; then \
		echo "Setting password from $(SECRET_FILE)..."; \
		docker exec -u 0 $(CONTAINER_NAME) sh -c "echo `whoami`:$$(cat $(SECRET_FILE)) | chpasswd"; \
	else \
		echo "Warning: $(SECRET_FILE) not found, skipping password setting"; \
	fi
	docker exec -u 0 $(CONTAINER_NAME) sed -i 's/^session/#session/' /etc/pam.d/sudo

# Remove container target - checks if container exists and asks for confirmation
rm-container:
	@if ! docker ps -a --format '{{.Names}}' | grep -q "^$(CONTAINER_NAME)$$"; then \
		echo "Container '$(CONTAINER_NAME)' does not exist."; \
		exit 0; \
	fi
	@if [ "$(FORCE)" != "true" ]; then \
		read -p "Are you sure you want to delete container '$(CONTAINER_NAME)'? [y/N] " confirm; \
		if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
			echo "Operation cancelled."; \
			exit 0; \
		fi; \
	fi
	docker rm -f $(CONTAINER_NAME)
	@echo "Container '$(CONTAINER_NAME)' has been removed."

# Secret file target - show info about secret file
secret-file:
	@if [ -f "$(SECRET_FILE)" ]; then \
		echo "Secret file exists: $(SECRET_FILE)"; \
		echo "Password length: $$(wc -c < $(SECRET_FILE)) characters"; \
	else \
		echo "Secret file not found: $(SECRET_FILE)"; \
		echo "To create it: echo 'yourpassword' > $(SECRET_FILE)"; \
		echo "Make sure to set proper permissions: chmod 600 $(SECRET_FILE)"; \
	fi

# Exec target - enter container shell
exec:
	docker exec -it $(CONTAINER_NAME) $(SPECIFIC_SHELL)
