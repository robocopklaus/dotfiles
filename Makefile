# The default shell is /bin/bash.
SHELL = /bin/bash
# Path to .dotfiles
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
# List all dotfiles
HOMEFILES := $(shell ls -A files | grep "^\.")
DOTFILES := $(addprefix $(HOME)/,$(HOMEFILES))

# Path to macOS user fonts
FONTS_DIR := $(HOME)/Library/Fonts

# Add Homebrew path for ARM-based Macs to PATH. Adjust this if using a different path.
export PATH := /opt/homebrew/bin:$(PATH)

# List of Homebrew packages and casks to install
BREW_PACKAGES := git volta antidote mas
BREW_CASKS := iterm2 visual-studio-code docker google-drive \
              1password notion slack google-chrome iina spotify \
              hpedrorodrigues/tools/dockutil finicky clockify fig \
              kap postman sketch tableplus whatsapp home-assistant \
              mimestream

# List of VS Code extensions to install
VS_CODE_EXTENSIONS := bernardodsanderson.theme-material-neutral \
                      pkief.material-icon-theme mechatroner.rainbow-csv \
                      mikestead.dotenv prisma.prisma dbaeumer.vscode-eslint \
                      vivaxy.vscode-conventional-commits bradlc.vscode-tailwindcss

.PHONY: all install brew-packages brew-casks addons \
        uninstall-brew-packages uninstall-brew-casks \
        vs-code-extensions uninstall-vscode-extensions \
        help link unlink sudo brew meslo-nerd-font macos-defaults dock-items

all: install

# Installation of packages, casks, and additional software
install: brew-packages brew-casks addons macos-defaults dock-items link
	@echo "Installation complete."

# Function to install Homebrew packages
define brew_install
    @echo "Installing $(1)..."
    brew list --versions $(1) > /dev/null || brew install --quiet $(1);
endef

# Homebrew cask installation
brew-casks: brew-taps
	echo "Updating and installing Homebrew casks..."
	if command -v brew >/dev/null 2>&1; then \
		$(foreach cask, $(BREW_CASKS), echo "Installing $(cask)..."; \
		brew list --cask --versions $(cask) > /dev/null || brew install --cask --quiet --no-quarantine --force $(cask);) \
		if echo "$(BREW_CASKS)" | grep -q "iterm2"; then \
			echo "Configuring iTerm2 with custom settings..."; \
			defaults write com.googlecode.iterm2 PrefsCustomFolder $(DOTFILES_DIR)/files; \
			defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true; \
		fi \
	else \
		echo "Homebrew is not installed."; \
	fi

# Homebrew cask installation
brew-casks: brew-taps
	@echo "Updating and installing Homebrew casks..."
	@if command -v brew >/dev/null 2>&1; then \
		$(foreach cask, $(BREW_CASKS), $(call brew_cask_install,$(cask));) \
		$(if $(filter iterm2,$(BREW_CASKS)), $(call configure_iterm2)) \
	else \
		echo "Homebrew is not installed."; \
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
	@echo "  brew-packages: Install specified Homebrew packages"
	@echo "  brew-casks: Install specified Homebrew casks"
	@echo "  link: Create symbolic links for dotfiles in the home directory"
	@echo "  meslo-nerd-font: Install Meslo LGS Nerd Font"
	@echo "  macos-defaults: Apply macOS default settings using a script"
	@echo "  unlink: Remove symbolic links for dotfiles in the home directory"
	@echo "  uninstall-all: Uninstall all packages, casks, VS Code extensions, and Homebrew"
	@echo "  uninstall-brew-packages: Uninstall Homebrew packages"
	@echo "  uninstall-brew-casks: Uninstall Homebrew casks"
	@echo "  uninstall-vscode-extensions: Uninstall specified VS Code extensions"
	@echo "  uninstall-brew: Uninstall Homebrew"
