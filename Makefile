# The default shell is /bin/bash.
SHELL = /bin/bash

# List all dotfiles
HOMEFILES := $(shell ls -A files | grep "^\.")
DOTFILES := $(addprefix $(HOME)/,$(HOMEFILES))

# Add Homebrew path for ARM-based Macs to PATH. Adjust this if using a different path.
export PATH := /opt/homebrew/bin:$(PATH)

# List of Homebrew packages and casks to install
BREW_PACKAGES := git volta antidote mas
BREW_CASKS := iterm2 visual-studio-code docker google-drive \
              1password notion slack google-chrome iina spotify \
              hpedrorodrigues/tools/dockutil finicky clockify fig \
              kap postman sketch tableplus whatsapp

# List of VS Code extensions to install
VS_CODE_EXTENSIONS := bernardodsanderson.theme-material-neutral \
                      pkief.material-icon-theme mechatroner.rainbow-csv \
                      mikestead.dotenv prisma.prisma dbaeumer.vscode-eslint \
                      vivaxy.vscode-conventional-commits bradlc.vscode-tailwindcss

.PHONY: sudo brew brew-packages brew-casks brew-taps \
        uninstall-brew-packages uninstall-brew-casks uninstall-all \
        vs-code-extensions uninstall-vscode-extensions help link unlink

all: install

# Installation of packages, casks, and additional software
install: brew-packages brew-casks addons link

# Homebrew package installation
brew-packages: brew-taps
	@echo "Updating Homebrew..."
	@if command -v brew >/dev/null 2>&1; then \
		brew update --quiet --force || { echo "Failed to update Homebrew"; exit 1; }; \
		echo "Installing Homebrew packages..."; \
		for package in $(BREW_PACKAGES); do \
			echo "Installing $$package..."; \
			brew list --versions $$package > /dev/null || brew install --quiet $$package; \
		done; \
	else \
		echo "Homebrew is not installed."; \
	fi

# Homebrew cask installation
brew-casks: brew-taps
	@echo "Installing Homebrew casks..."
	@if command -v brew >/dev/null 2>&1; then \
		for cask in $(BREW_CASKS); do \
			echo "Installing $$cask..."; \
			brew list --cask --versions $$cask > /dev/null || brew install --cask --quiet --no-quarantine --force $$cask; \
		done; \
	else \
		echo "Homebrew is not installed."; \
	fi

addons: vs-code-extensions

# Uninstall Homebrew packages
uninstall-brew-packages:
	@echo "Uninstalling Homebrew packages..."
	@for package in $(BREW_PACKAGES); do \
		echo "Uninstalling $$package..."; \
		brew uninstall $$package || echo "Failed to uninstall $$package"; \
	done

# Uninstall Homebrew casks
uninstall-brew-casks:
	@echo "Uninstalling Homebrew casks..."
	@for cask in $(BREW_CASKS); do \
		echo "Uninstalling $$cask..."; \
		brew uninstall --cask $$cask || echo "Failed to uninstall $$cask"; \
	done

# Uninstall specified Visual Studio Code extensions
uninstall-vscode-extensions:
	@echo "Uninstalling specified Visual Studio Code extensions..."
	@if command -v code >/dev/null 2>&1; then \
		for extension in $(VS_CODE_EXTENSIONS); do \
			echo "Uninstalling $$extension..."; \
			code --uninstall-extension $$extension || echo "Failed to uninstall $$extension"; \
		done; \
	else \
		echo "Visual Studio Code is not installed."; \
	fi

# Uninstall all Homebrew packages, casks, VS Code extensions, and Homebrew itself
uninstall-all: uninstall-brew-packages uninstall-brew-casks uninstall-vscode-extensions uninstall-brew

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
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | NONINTERACTIVE=1 bash; \
		if [ $$? -ne 0 ]; then \
			echo "Failed to install Homebrew"; \
			exit 1; \
		fi; \
		echo "Homebrew installed and configured successfully."; \
	else \
		echo "Homebrew is already installed."; \
	fi

vs-code-extensions:
	@echo "Installing Visual Studio Code extensions..."
	@if command -v code >/dev/null 2>&1; then \
		for extension in $(VS_CODE_EXTENSIONS); do \
			echo "Installing $$extension..."; \
			code --install-extension $$extension || echo "Failed to install $$extension"; \
		done; \
	else \
		echo "Visual Studio Code is not installed."; \
	fi

# brew-taps target for adding additional repositories.
brew-taps: brew

# uninstall-brew target removes Homebrew if it's installed.
uninstall-brew: sudo
	@echo "Checking for Homebrew installation..."
	@if command -v brew >/dev/null 2>&1; then \
		echo "Uninstalling Homebrew..."; \
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh | NONINTERACTIVE=1 bash || { echo "Failed to uninstall Homebrew"; exit 1; } \
	else \
		echo "Homebrew is not installed."; \
	fi

link: | $(DOTFILES)
	@echo "Linking dotfiles to the home directory..."
	@for file in $(HOMEFILES); do \
		if [ -f "files/$$file" ]; then \
			ln -sfv "$(PWD)/files/$$file" "$(HOME)/$$file"; \
		else \
			echo "Warning: $$file not found in files directory"; \
		fi; \
	done

# This will link all of our dot files into our files directory. The
# magic happening in the first arg to ln is just grabbing the file name
# and appending the path to dotfiles/home
$(DOTFILES):
	@ln -sfv "$(PWD)/files/$(notdir $@)" $@

unlink:
	@echo "Unlinking dotfiles from the home directory..."
	@for f in $(DOTFILES); do \
		if [ -h $$f ]; then \
			echo "Removing link $$f"; \
			rm -i $$f; \
		fi; \
	done

# Help target to display Makefile usage
help:
	@echo "Available targets:"
	@echo "  install: Install Homebrew packages, casks, and addons"
	@echo "  brew-packages: Install specified Homebrew packages"
	@echo "  brew-casks: Install specified Homebrew casks"
	@echo "  addons: Install additional software like VS Code extensions"
	@echo "  link: Create symbolic links for dotfiles in the home directory"
	@echo "  unlink: Remove symbolic links for dotfiles in the home directory"
	@echo "  uninstall-all: Uninstall all packages, casks, and VS Code extensions"
	@echo "  uninstall-brew-packages: Uninstall Homebrew packages"
	@echo "  uninstall-brew-casks: Uninstall Homebrew casks"
	@echo "  uninstall-vscode-extensions: Uninstall specified VS Code extensions"
	@echo "  uninstall-brew: Uninstall Homebrew"
