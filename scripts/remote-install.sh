#!/usr/bin/env bash

DOTFILES_PATH="$HOME/.dotfiles"

sudo -v

# Update macOS
sudo softwareupdate -i -a

# Install Command Line Tools
os=$(sw_vers -productVersion | awk -F. '{print $1 "." $2}')
if softwareupdate --history | grep --silent "Command Line Tools.*${os}"; then
    echo 'Command-line tools already installed.' 
else
    echo 'Installing Command-line tools...'
    in_progress=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    touch ${in_progress}
    product=$(softwareupdate --list | awk "/\* Command Line.*${os}/ { sub(/^   \* /, \"\"); print }")
    softwareupdate --verbose --install "${product}" || echo 'Installation failed.' 1>&2 && rm ${in_progress} && exit 1
    rm ${in_progress}
    echo 'Installation succeeded.'
fi

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