SHELL = /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PATH := $(DOTFILES_DIR)/bin:$(PATH)
FILES_DIR := $(DOTFILES_DIR)/files
OH_MY_ZSH_DIR := $(HOME)/.oh-my-zsh
FONTS_DIR := $(HOME)/Library/Fonts

all: sudo brew packages system-preferences symlinks

sudo:
ifndef GITHUB_ACTION
	@sudo -v
	@while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
endif

brew:
	@is-command brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash

packages: brew-packages oh-my-zsh vs-code-extensions package-post-install-fixes meslo-nerd-font

brew-packages: brew
	@brew update --force	
	@HOMEBREW_CASK_OPTS="--no-quarantine" brew bundle --no-lock
	@brew cleanup

oh-my-zsh:
	@is-directory $(OH_MY_ZSH_DIR) || curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash

vs-code-extensions:
	@for EXT in $$(cat Codefile); do code --install-extension $$EXT; done

package-post-install-fixes:
	@export DOTFILES_DIR
	@$(SHELL) scripts/post-install-iterm2-fix.sh
	@sudo curl -sL https://raw.githubusercontent.com/kcrawford/dockutil/master/scripts/dockutil -o $(shell which dockutil) && sudo chmod +x $(shell which dockutil)

meslo-nerd-font:
	@echo Installing Meslo LGS Nerd Font...
	@is-directory $(FONTS_DIR) || mkdir -p "$(FONTS_DIR)"
	@curl -s -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -o "$(FONTS_DIR)/Meslo LGS NF Regular.ttf"
	@curl -s -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -o "$(FONTS_DIR)/Meslo LGS NF Bold.ttf"
	@curl -s -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -o "$(FONTS_DIR)/Meslo LGS NF Italic.ttf"
	@curl -s -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -o "$(FONTS_DIR)/Meslo LGS NF Bold Italic.ttf"

system-preferences:
	@$(SHELL) scripts/macos-system-preferences.sh
	@$(SHELL) scripts/dock-items.sh

symlinks:
	@echo Creating symlinks...
	@ln -nsf $(FILES_DIR)/.antigenrc $(HOME)/.antigenrc
	@ln -nsf $(FILES_DIR)/.editorconfig $(HOME)/.editorconfig
	@ln -nsf $(FILES_DIR)/.gitconfig $(HOME)/.gitconfig
	@ln -nsf $(FILES_DIR)/.gitignore $(HOME)/.gitignore
	@ln -nsf $(FILES_DIR)/.p10k.zsh $(HOME)/.p10k.zsh
	@ln -nsf $(FILES_DIR)/.zshrc $(HOME)/.zshrc
	@mkdir -p "$(HOME)/Library/Application Support/Code/User"
	@ln -nsf $(FILES_DIR)/vscode.settings.json "$(HOME)/Library/Application Support/Code/User/settings.json"

test:
	@brew install bats-core
	@bats tests
	@brew rm bats-core
	@brew cleanup