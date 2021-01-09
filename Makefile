# The default shell is /bin/sh. We use bash
SHELL = /bin/bash
# Path to oh-my-zsh
OH_MY_ZSH_DIR := $(HOME)/.oh-my-zsh
# Path to .dotfiles
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
# Path to dockutil script
DOCKUTIL_PATH = /usr/local/bin/dockutil
# PATH := $(DOTFILES_DIR)/bin:$(PATH)
# FILES_DIR := $(DOTFILES_DIR)/files
# FONTS_DIR := $(HOME)/Library/Fonts

# Helper functions
install_vscode_extension = code --install-extension $(1)
install_brew_package = brew list --versions $(1) > /dev/null || brew install $(1)
install_brew_cask = brew list --cask --versions $(1) > /dev/null || brew install --cask --no-quarantine  --force $(1) 
uninstall_brew_package = brew rm $$(brew deps $(1)) $(1)
uninstall_brew_cask = brew rm $(1)

# Do not care about local files
.PHONY: all sudo install-brew install-packages oh-my-zsh vs-code-extensions package-post-install-fixes meslo-nerd-font system-preferences symlinks test

# all: sudo brew packages system-preferences symlinks
all: install-packages

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

install-oh-my-zsh:
	@[[ ! -d $(OH_MY_ZSH_DIR) ]] && curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash

uninstall-oh-my-zsh:
# https://github.com/ohmyzsh/ohmyzsh/wiki/FAQ#how-do-i-uninstall-oh-my-zsh
	#curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/uninstall.sh | bash

install-vs-code-extensions:
	@$(call install_vscode_extension,bernardodsanderson.theme-material-neutral)
	@$(call install_vscode_extension,PKief.material-icon-theme)
	@$(call install_vscode_extension,sharat.vscode-brewfile)

test:
	@brew unlink bats
	@$(call install_brew_package,bats-core)
	@bats tests
	@$(call uninstall_brew_package,bats-core)
# @brew rm bats-core
	@brew cleanup

# Browsers
# cask "google-chrome"
# cask "firefox-developer-edition"

# Productivity
# cask "google-drive-file-stream"
# cask "1password"
# brew "dockutil"
# cask "notion"
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

# install-brew-packages: install-brew
# 	@brew update --force	
# 	@HOMEBREW_CASK_OPTS="--no-quarantine" brew bundle --no-lock
# 	@brew cleanup

# uninstall-brew-packages:
# 	echo $$(brew bundle list --formula)
# 	echo $$(brew list --formula)
	
# install-packages: install-brew-packages oh-my-zsh vs-code-extensions package-post-install-fixes meslo-nerd-font



# oh-my-zsh:
# 	@is-directory $(OH_MY_ZSH_DIR) || curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash

# vs-code-extensions:
# 	@for EXT in $$(cat Codefile); do code --install-extension $$EXT; done

# package-post-install-fixes:
# 	@export DOTFILES_DIR
# 	@$(SHELL) scripts/post-install-iterm2-fix.sh
# 	@sudo curl -sL https://raw.githubusercontent.com/kcrawford/dockutil/master/scripts/dockutil -o $(shell which dockutil) && sudo chmod +x $(shell which dockutil)

# meslo-nerd-font:
# 	@echo Installing Meslo LGS Nerd Font...
# 	@is-directory $(FONTS_DIR) || mkdir -p "$(FONTS_DIR)"
# 	@curl -sL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -o "$(FONTS_DIR)/Meslo LGS NF Regular.ttf"
# 	@curl -sL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -o "$(FONTS_DIR)/Meslo LGS NF Bold.ttf"
# 	@curl -sL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -o "$(FONTS_DIR)/Meslo LGS NF Italic.ttf"
# 	@curl -sL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -o "$(FONTS_DIR)/Meslo LGS NF Bold Italic.ttf"

# system-preferences:
# 	@$(SHELL) scripts/macos-system-preferences.sh
# 	@$(SHELL) scripts/dock-items.sh

# symlinks:
# 	@echo Creating symlinks...
# 	@ln -nsf $(FILES_DIR)/.antigenrc $(HOME)/.antigenrc
# 	@ln -nsf $(FILES_DIR)/.editorconfig $(HOME)/.editorconfig
# 	@ln -nsf $(FILES_DIR)/.gitconfig $(HOME)/.gitconfig
# 	@ln -nsf $(FILES_DIR)/.gitignore $(HOME)/.gitignore
# 	@ln -nsf $(FILES_DIR)/.p10k.zsh $(HOME)/.p10k.zsh
# 	@ln -nsf $(FILES_DIR)/.zshrc $(HOME)/.zshrc
# 	@mkdir -p "$(HOME)/Library/Application Support/Code/User"
# 	@ln -nsf $(FILES_DIR)/vscode.settings.json "$(HOME)/Library/Application Support/Code/User/settings.json"

# test:
# 	@brew install bats-core
# 	@bats tests
# 	@brew rm bats-core
# 	@brew cleanup

# foo:
# 	if ! command -v $1 >/dev/null; then echo "Not installed"; fi