SHELL = /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PATH := $(DOTFILES_DIR)/bin:$(PATH)

all: sudo brew packages system-preferences

sudo:
ifndef GITHUB_ACTION
	@sudo -v
	@while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
endif

brew:
	@is-command brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash

packages: brew-packages package-post-install-fixes

brew-packages: brew
	@brew update --force	
	@HOMEBREW_CASK_OPTS="--no-quarantine" brew bundle --no-lock
	@brew cleanup

package-post-install-fixes:
	@defaults write com.googlecode.iterm2 PrefsCustomFolder "$(DOTFILES_DIR)/files"

system-preferences:
	@$(SHELL) scripts/macos-system-preferences.sh

test:
	@brew install bats-core
	@bats tests
	@brew rm bats-core
	@brew cleanup