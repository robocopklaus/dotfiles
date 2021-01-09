# The default shell is /bin/sh. We use bash
SHELL = /bin/bash
# Path to oh-my-zsh
OH_MY_ZSH_DIR := $(HOME)/.oh-my-zsh
# Path to .dotfiles
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
# List all dotfiles
HOMEFILES := $(shell ls -A files | grep "^\.")
DOTFILES := $(addprefix $(HOME)/,$(HOMEFILES))
# Path to dockutil script
DOCKUTIL_PATH = /usr/local/bin/dockutil
# Path to macOS user fonts
FONTS_DIR := $(HOME)/Library/Fonts

# Helper functions
install_vscode_extension = code --install-extension $(1)
install_brew_package = brew list --versions $(1) > /dev/null || brew install $(1)
install_brew_cask = brew list --cask --versions $(1) > /dev/null || brew install --cask --no-quarantine  --force $(1) 
uninstall_brew_package = brew rm $$(brew deps $(1)) $(1)
uninstall_brew_cask = brew rm $(1)

# Do not care about local files
.PHONY: all sudo install-brew uninstall-brew install-packages install-brew-packages install-oh-my-zsh uninstall-oh-my-zsh install-addons install-vs-code-extensions install-meslo-nerd-font macos-preferences link unlink test

all: install-packages install-addons macos-preferences link

sudo:
ifndef GITHUB_ACTION
	@sudo -v
	@while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
endif

install-brew: sudo
	@if ! command -v brew >/dev/null; then curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash; fi

uninstall-brew: sudo
	@if command -v brew >/dev/null; then curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh | bash; fi

install-packages: install-brew-packages install-oh-my-zsh

install-brew-packages: install-brew
	@brew update --force	
# Programming language prerequisites and package managers
	@$(call install_brew_package,git)
	@$(call install_brew_package,volta)
# Terminal tools
	@$(call install_brew_package,antigen)
	@$(call install_brew_cask,iterm2)
	@defaults write com.googlecode.iterm2 PrefsCustomFolder $(DOTFILES_DIR)/files
	@defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
# Dev tools
	@$(call install_brew_cask,docker)
	@$(call install_brew_cask,tableplus)
	@$(call install_brew_cask,visual-studio-code)
# Productivity
	@$(call install_brew_package,dockutil)
	@sudo curl -sL https://raw.githubusercontent.com/kcrawford/dockutil/master/scripts/dockutil -o $(DOCKUTIL_PATH) && sudo chmod +x $(DOCKUTIL_PATH)
	@$(call install_brew_cask,google-drive-file-stream)
	@$(call install_brew_cask,1password)
	@$(call install_brew_cask,notion)

install-oh-my-zsh:
	@[[ ! -d $(OH_MY_ZSH_DIR) ]] && curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash

uninstall-oh-my-zsh:
# https://github.com/ohmyzsh/ohmyzsh/wiki/FAQ#how-do-i-uninstall-oh-my-zsh
	#curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/uninstall.sh | bash

install-addons: install-vs-code-extensions install-meslo-nerd-font

install-vs-code-extensions:
	@$(call install_vscode_extension,bernardodsanderson.theme-material-neutral)
	@$(call install_vscode_extension,PKief.material-icon-theme)
	@$(call install_vscode_extension,sharat.vscode-brewfile)

install-meslo-nerd-font:
	@echo Installing Meslo LGS Nerd Font...
	@[[ -d $(FONTS_DIR) ]] || mkdir -p "$(FONTS_DIR)"
	@curl -sL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -o "$(FONTS_DIR)/Meslo LGS NF Regular.ttf"
	@curl -sL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -o "$(FONTS_DIR)/Meslo LGS NF Bold.ttf"
	@curl -sL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -o "$(FONTS_DIR)/Meslo LGS NF Italic.ttf"
	@curl -sL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -o "$(FONTS_DIR)/Meslo LGS NF Bold Italic.ttf"

macos-preferences:
	@$(SHELL) scripts/macos-system-preferences.sh
#	@$(SHELL) scripts/dock-items.sh

link: | $(DOTFILES)
	@[[ -d "$(HOME)/Library/Application Support/Code/User" ]] || mkdir -p "$(HOME)/Library/Application Support/Code/User"
	@ln -nsf $(DOTFILES_DIR)/files/vscode.settings.json "$(HOME)/Library/Application Support/Code/User/settings.json"

# This will link all of our dot files into our files directory. The
# magic happening in the first arg to ln is just grabbing the file name
# and appending the path to dotfiles/home
$(DOTFILES):
	@ln -sv "$(PWD)/files/$(notdir $@)" $@

# Interactively delete symbolic links.
unlink:
	@echo "Unlinking dotfiles"
	@for f in $(DOTFILES); do if [ -h $$f ]; then rm -i $$f; fi ; done

test:
	@brew unlink bats
	@$(call install_brew_package,bats-core)
	@bats tests
	@$(call uninstall_brew_package,bats-core)
	@brew cleanup

# Browsers
# cask "google-chrome"
# cask "firefox-developer-edition"

# Productivity
# mas 'Keynote', id: 409183694
# mas 'Numbers', id: 409203825
# mas "Pages", id: 409201541

# Utils
# cask "keka"
# cask "kekaexternalhelper"

# Communication
# cask "slack"

# Time Tracking
# cask "clockify"

# Music
# cask "spotify"

# Video
# cask "iina"
