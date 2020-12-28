SHELL = /bin/bash
export DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PATH := $(DOTFILES_DIR)/bin:$(PATH)
FILES_DIR := $(DOTFILES_DIR)/files
OH_MY_ZSH_DIR := $(HOME)/.oh-my-zsh
POWERLEVEL10K_DIR := $(OH_MY_ZSH_DIR)/custom/themes/powerlevel10k

all: sudo brew packages system-preferences symlinks

sudo:
ifndef GITHUB_ACTION
	@sudo -v
	@while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
endif

brew:
	@is-command brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash

packages: brew-packages oh-my-zsh package-post-install-fixes

brew-packages: brew
	@brew update --force	
	@HOMEBREW_CASK_OPTS="--no-quarantine" brew bundle --no-lock
	@brew cleanup

oh-my-zsh:
	@is-directory $(OH_MY_ZSH_DIR) || curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash

powerlevel10k:
	@is-directory $(POWERLEVEL10K_DIR) || git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $(POWERLEVEL10K_DIR)

package-post-install-fixes:
	@$(SHELL) scripts/post-install-iterm2-fix.sh

system-preferences:
	@$(SHELL) scripts/macos-system-preferences.sh

symlinks:
	ln -nsf $(FILES_DIR)/zshrc ~/.zshrc

test:
	@brew install bats-core
	@bats tests
	@brew rm bats-core
	@brew cleanup