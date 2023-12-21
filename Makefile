# The default shell is /bin/bash.
SHELL = /bin/bash

# Add Homebrew path for ARM-based Macs to PATH. Adjust this if using a different path.
export PATH := /opt/homebrew/bin:$(PATH)

# Declare phony targets to ensure these rules run even if files with these names exist.
.PHONY: sudo brew verify-brew uninstall-brew brew-packages brew-taps

all: install

install: brew-packages

brew-packages: brew-taps
	@echo "Updating Homebrew..."
	@brew update --force || { echo "Failed to update Homebrew"; exit 1; }

brew-taps: verify-brew
	# Add commands to tap additional repositories here, if necessary.

# sudo target keeps the sudo session alive for the duration of the make process.
sudo:
ifndef GITHUB_ACTION
	@echo "Keeping sudo session alive..."
	@sudo -v
	@while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
endif

# brew target installs Homebrew if it's not already installed.
brew: sudo
	@echo "Checking for Homebrew installation..."
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "Installing Homebrew..."; \
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash; \
		if [ $$? -ne 0 ]; then \
			echo "Failed to install Homebrew"; \
			exit 1; \
		fi; \
		echo "Configuring Homebrew for ARM-based Macs..."; \
		eval "$$(/opt/homebrew/bin/brew shellenv)"; \
		echo "Homebrew installed and configured successfully."; \
	else \
		echo "Homebrew is already installed."; \
	fi

# verify-brew target checks for the presence of Homebrew.
verify-brew:
	@echo "Verifying Homebrew installation..."
	@if [ -x "/opt/homebrew/bin/brew" ]; then \
		echo "Homebrew is installed"; \
	else \
		echo "Homebrew is not installed"; \
		exit 1; \
	fi

# uninstall-brew target removes Homebrew if it's installed.
uninstall-brew: sudo
	@echo "Checking for Homebrew installation..."
	@if command -v brew >/dev/null 2>&1; then \
		echo "Uninstalling Homebrew..."; \
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh | bash || { echo "Failed to uninstall Homebrew"; exit 1; } \
	else \
		echo "Homebrew is not installed."; \
	fi
