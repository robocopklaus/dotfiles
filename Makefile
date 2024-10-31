# The default shell is /bin/bash.
SHELL = /bin/bash
# Path to .dotfiles
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
# List all dotfiles
HOMEFILES := $(wildcard files/.*)
DOTFILES := $(addprefix $(HOME)/,$(notdir $(HOMEFILES)))

# Path to macOS user fonts
FONTS_DIR := $(HOME)/Library/Fonts

# SSH configuration
SSH_DIR := $(HOME)/.ssh
SSH_CONFIG := files/ssh/config

# Add Homebrew path for ARM-based Macs to PATH. Adjust this if using a different path.
export PATH := /opt/homebrew/bin:$(PATH)

# List of Homebrew packages and casks to install
BREW_PACKAGES := git volta antidote mas dockutil 1password-cli
BREW_CASKS := iterm2 visual-studio-code docker google-drive \
              1password notion slack google-chrome iina spotify \
			  finicky clockify herd mimestream chatgpt \
			  kap postman sketch tableplus whatsapp home-assistant

# List of VS Code extensions to install
VS_CODE_EXTENSIONS := bernardodsanderson.theme-material-neutral \
					  pkief.material-icon-theme mechatroner.rainbow-csv \
					  mikestead.dotenv github.copilot github.copilot-chat \
					  oderwat.indent-rainbow

# List of macOS App Store apps to install
MAS_APPS := 1568262835  # Super Agent
MAS_APPS += 1569813296  # 1Password for Safari
MAS_APPS += 1107163858  # GCal for Google Calendar
MAS_APPS += 409203825  # Numbers
MAS_APPS += 409201541  # Pages

.PHONY: all install brew-packages-casks mas-apps addons \
		uninstall-brew-packages uninstall-brew-casks \
		vs-code-extensions uninstall-vscode-extensions \
		help link unlink sync-ssh-config sudo brew meslo-nerd-font macos-defaults dock-items

all: install

# Installation of packages, casks, and additional software
install: brew-packages-casks mas-apps addons macos-defaults dock-items sync-ssh-config link
	@echo "Installation complete."

# Homebrew package and cask installation
brew-packages-casks: brew-taps
	@echo "Updating and installing Homebrew packages and casks..."
	@if command -v brew >/dev/null 2>&1; then \
		brew update --quiet --force || { echo "Failed to update Homebrew"; exit 1; }; \
		for package in $(BREW_PACKAGES); do \
			echo "Installing $$package..."; \
			if ! brew list --versions $$package > /dev/null; then \
				brew install --quiet $$package || { echo "Failed to install $$package"; exit 1; }; \
			fi; \
		done; \
		for cask in $(BREW_CASKS); do \
			echo "Installing $$cask..."; \
			brew list --cask --versions $$cask > /dev/null || brew install --cask --quiet --no-quarantine --force $$cask; \
		done; \
		if echo "$(BREW_CASKS)" | grep -q "iterm2"; then \
			echo "Configuring iTerm2 with custom settings..."; \
			defaults write com.googlecode.iterm2 PrefsCustomFolder $(DOTFILES_DIR)/files; \
			defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true; \
		fi \
	else \
		echo "Homebrew is not installed."; \
	fi

# Install macOS App Store apps
mas-apps:
	@echo "Installing macOS App Store apps..."
	@if command -v mas >/dev/null 2>&1; then \
		for app in $(MAS_APPS); do \
			echo "Installing app ID $$app..."; \
			mas install $$app || echo "Failed to install app ID $$app"; \
		done; \
	else \
		echo "mas is not installed."; \
	fi

addons: vs-code-extensions meslo-nerd-font

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

# Function to download and install Meslo Nerd Font
define download_font
	@font_name="MesloLGS NF $(1)"; \
	font_url="https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20$(1).ttf"; \
	font_url=$$(echo "$$font_url" | sed 's/ /%20/g'); \
	font_file="$${font_name}.ttf"; \
	echo "Processing $$font_file..."; \
	if [[ ! -f "$(FONTS_DIR)/$$font_file" ]]; then \
		echo "Downloading $$font_file..."; \
		curl -sL "$$font_url" -o "$(FONTS_DIR)/$$font_file" && echo "$$font_file downloaded." || { echo "Failed to download $$font_file"; exit 1; }; \
	else \
		echo "$$font_file already installed."; \
	fi;
endef

meslo-nerd-font:
	@echo "Installing Meslo LGS Nerd Font..."
	@[[ -d $(FONTS_DIR) ]] || mkdir -p "$(FONTS_DIR)"
	@$(call download_font,Regular)
	@$(call download_font,Bold)
	@$(call download_font,Italic)
	@$(call download_font,Bold Italic)

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

sync-ssh-config:
	@echo "Setting up SSH config symlink..."
	@mkdir -p $(SSH_DIR) && chmod 700 $(SSH_DIR)
	@if [ -f $(SSH_CONFIG) ]; then \
			ln -sfv "$(PWD)/$(SSH_CONFIG)" "$(SSH_DIR)/config"; \
		else \
			echo "Warning: $(SSH_CONFIG) not found"; \
		fi;
	@echo "SSH config symlink created successfully."

link: | $(DOTFILES)
	@echo "Linking dotfiles to the home directory..."
	@for file in $(notdir $(HOMEFILES)); do \
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

# Apply macOS defaults
macos-defaults:
	@echo "Applying macOS default settings..."
	@if [ -f scripts/macos-defaults.sh ]; then \
		$(SHELL) scripts/macos-defaults.sh || { echo "Failed to apply macOS defaults"; exit 1; }; \
	else \
		echo "macOS defaults script not found."; \
	fi

# Customize Dock items
dock-items:
	@echo "Customizing Dock items..."
	@if [ -f scripts/dock-items.sh ] && [ -x scripts/dock-items.sh ]; then \
		$(SHELL) scripts/dock-items.sh; \
	else \
		echo "Dock items customization script not found or not executable."; \
	fi

# Help target to display Makefile usage
help:
	@echo "Available targets:"
	@echo "  install: Install Homebrew packages, casks, addons, and link dotfiles"
	@echo "  addons: Install addons like VS Code extensions and fonts"
	@echo "  brew-packages-casks: Install specified Homebrew packages and casks"
	@echo "  mas-apps: Install specified macOS App Store apps"
	@echo "  link: Create symbolic links for dotfiles in the home directory"
	@echo "  meslo-nerd-font: Install Meslo LGS Nerd Font"
	@echo "  macos-defaults: Apply macOS default settings using a script"
	@echo "  unlink: Remove symbolic links for dotfiles in the home directory"
	@echo "  uninstall-all: Uninstall all packages, casks, VS Code extensions, and Homebrew"
	@echo "  uninstall-brew-packages: Uninstall Homebrew packages"
	@echo "  uninstall-brew-casks: Uninstall Homebrew casks"
	@echo "  uninstall-vscode-extensions: Uninstall specified VS Code extensions"
	@echo "  uninstall-brew: Uninstall Homebrew"
