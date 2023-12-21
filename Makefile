# The default shell is /bin/bash.
SHELL = /bin/bash

# Add Homebrew path for ARM-based Macs to PATH. Adjust this if using a different path.
export PATH := /opt/homebrew/bin:$(PATH)

# List of Homebrew packages to install
BREW_PACKAGES := git volta antidote

# List of Homebrew casks to install
BREW_CASKS := iterm2 visual-studio-code

# Declare phony targets to ensure these rules run even if files with these names exist.
.PHONY: sudo brew brew-packages brew-taps cleanup

all: install

install: brew-casks brew-packages

brew-packages: brew-taps
	@echo "Updating Homebrew..."
	@brew update --force || { echo "Failed to update Homebrew"; exit 1; }

	# Install listed Homebrew packages
	@for package in $(BREW_PACKAGES); do \
		echo "Installing $$package..."; \
		brew list --versions $$package > /dev/null || brew install $$package; \
	done

brew-casks: brew-taps
	@echo "Installing Homebrew casks..."
	@for cask in $(BREW_CASKS); do \
		echo "Installing $$cask..."; \
		brew list --cask --versions $$cask > /dev/null || brew install --cask --no-quarantine --force $$cask; \
	done

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
		echo "Homebrew installed and configured successfully."; \
	else \
		echo "Homebrew is already installed."; \
	fi

# brew-taps target for adding additional repositories.
brew-taps: brew
	# Add commands to tap additional repositories here, if necessary.

# cleanup target for maintenance tasks.
cleanup:
	@echo "Running Homebrew cleanup..."
	@brew cleanup

# uninstall-brew target removes Homebrew if it's installed.
uninstall-brew: sudo
	@echo "Checking for Homebrew installation..."
	@if command -v brew >/dev/null 2>&1; then \
		echo "Uninstalling Homebrew..."; \
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh | bash || { echo "Failed to uninstall Homebrew"; exit 1; } \
	else \
		echo "Homebrew is not installed."; \
	fi
