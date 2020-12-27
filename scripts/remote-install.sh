#!/usr/bin/env bash

DOTFILES_PATH="$HOME/.dotfiles"

sudo -v

# Update macOS
sudo softwareupdate -i -a

# Install Command Line Tools
if [ $(xcode-select -p 1>/dev/null;echo $?) -eq 2 ]; then
  xcode-select --install
fi

if [ ! -d "$DOTFILES_PATH" ]; then
  echo "Installing dotfiles..."
  git clone https://github.com/robocopklaus/dotfiles.git $DOTFILES_PATH
else
  echo "Updating dotfiles..."
  git -C $DOTFILES_PATH pull --rebase
fi

cd $DOTFILES_PATH
make