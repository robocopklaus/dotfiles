#!/usr/bin/env bash

DOTFILES_PATH="$HOME/.dotfiles"

sudo -v

# Update macOS
sudo softwareupdate -i -a

# Install Command Line Tools
touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
PROD=$(softwareupdate -l |
  grep "\*.*Command Line.*$(sw_vers -productVersion|awk -F. '{print $1"."$2}')" |
  head -n 1 | awk -F"*" '{print $2}' |
  sed -e 's/^ *//' |
  tr -d '\n')
softwareupdate -i "$PROD" --verbose
rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

# if [ $(xcode-select -p 1>/dev/null;echo $?) -eq 2 ]; then
#   xcode-select --install
# fi

if [ ! -d "$DOTFILES_PATH" ]; then
  echo "Installing dotfiles..."
  git clone https://github.com/robocopklaus/dotfiles.git $DOTFILES_PATH
else
  echo "Updating dotfiles..."
  git -C $DOTFILES_PATH pull --rebase
fi

cd $DOTFILES_PATH
make