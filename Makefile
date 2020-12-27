SHELL = /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PATH := $(DOTFILES_DIR)/bin:$(PATH)

all: sudo brew packages system-preferences

sudo:
ifndef GITHUB_ACTION
	sudo -v
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
endif

brew:
	is-command brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash

packages: brew-packages

brew-packages: brew
	#brew update --force	
	brew bundle
	brew cleanup

system-preferences:
	$(SHELL) config/macos-system-preferences.sh

test:
	brew install bats-core
	bats tests
	brew rm bats-core
	brew cleanup