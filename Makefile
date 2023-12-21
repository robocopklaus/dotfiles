# The default shell is /bin/bash.
SHELL = /bin/bash

# Declare phony targets to ensure these rules run even if files with these names exist.
.PHONY: sudo brew brew-packages brew-taps

all: install

install: brew-packages

brew-packages: brew
	@echo "Updating Homebrew..."
	@/opt/homebrew/bin/brew update --force || { echo "Failed to update Homebrew"; exit 1; }

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
		export PATH="/opt/homebrew/bin:$$PATH"; \
		echo "Homebrew installed and configured successfully."; \
	else \
		echo "Homebrew is already installed."; \
	fi

# brew-taps target can be defined here if you have additional taps to add.
brew-taps:
	# Add commands to tap additional repositories here, if necessary.

# uninstall-brew target removes Homebrew if it's installed.
uninstall-brew: sudo
	@echo "Checking for Homebrew installation..."
	@if command -v brew >/dev/null 2>&1; then \
		echo "Uninstalling Homebrew..."; \
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh | bash || { echo "Failed to uninstall Homebrew"; exit 1; } \
	else \
		echo "Homebrew is not installed."; \
	fi
