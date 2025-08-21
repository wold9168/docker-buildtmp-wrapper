# Makefile for Docker container management
# Usage: make run-container IMAGE=your_image_name [CONTAINER_NAME=your_container_name]

.PHONY: run-container update rm-container exec

# Set default container name if not provided
CONTAINER_NAME ?= buildtmp

# Set default shell if not provided
SPECIFIC_SHELL ?= bash

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
	docker run -itd --name $(CONTAINER_NAME) -v ~/docker/_template:/root/ -u `id -u`:`id -g` $(IMAGE)

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

# Exec target - enter container shell
exec:
	docker exec -it $(CONTAINER_NAME) $(SPECIFIC_SHELL)
