#!/usr/bin/env zsh

# Define the path to the dotfiles directory.
DOTFILES_PATH="$HOME/.dotfiles"

# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Update macOS to the latest version.
echo "Updating macOS..."
sudo softwareupdate -i -a

# Install Command Line Tools for Xcode if not present.
if ! [ -e "/Library/Developer/CommandLineTools/usr/bin/git" ]; then
  echo "Installing Command Line Tools..."
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
  PROD=$(softwareupdate -l | grep "*.*Command Line" | tail -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | sed 's/Label: //g' | tr -d '\n')
  softwareupdate -i "$PROD" --verbose
  rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
fi

# Clone or update the dotfiles repository.
if [ ! -d "$DOTFILES_PATH" ]; then
  echo "Cloning dotfiles..."
  git clone -b next https://github.com/robocopklaus/dotfiles.git "$DOTFILES_PATH" || { echo "Failed to clone dotfiles."; exit 1; }
else
  echo "Updating dotfiles..."
  git -C "$DOTFILES_PATH" pull --rebase || { echo "Failed to update dotfiles."; exit 1; }
fi

# Navigate to the dotfiles directory and run the Makefile.
cd "$DOTFILES_PATH" || { echo "Failed to navigate to dotfiles directory."; exit 1; }
echo "Running Makefile..."
make || { echo "Make process failed."; exit 1; }
