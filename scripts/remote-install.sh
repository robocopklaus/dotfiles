#!/usr/bin/env bash

# Define the path to the dotfiles directory.
DOTFILES_DIR="$HOME/.dotfiles"

# Function to ask for the administrator password upfront.
ask_for_sudo() {
  sudo -v
  # Keep-alive: update existing `sudo` time stamp until the script has finished.
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

# Function to update macOS to the latest version.
update_macos() {
  echo "Updating macOS..."
  sudo softwareupdate -i -a || { echo "Failed to update macOS."; exit 1; }
}

# Function to install Command Line Tools for Xcode if not present.
install_xcode_cli_tools() {
  if ! [ -e "/Library/Developer/CommandLineTools/usr/bin/git" ]; then
    echo "Installing Command Line Tools..."
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    PROD=$(softwareupdate -l | grep "*.*Command Line" | tail -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | sed 's/Label: //g' | tr -d '\n')
    sudo softwareupdate -i "$PROD" --verbose || { echo "Failed to install Command Line Tools."; exit 1; }
    rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  fi
}

# Function to clone or update the dotfiles repository.
update_dotfiles_repo() {
  if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles..."
    git clone -b next https://github.com/robocopklaus/dotfiles.git "$DOTFILES_DIR" || { echo "Failed to clone dotfiles."; exit 1; }
  else
    echo "Updating dotfiles..."
    git -C "$DOTFILES_DIR" pull --rebase || { echo "Failed to update dotfiles."; exit 1; }
  fi
}

# Function to run the Makefile in the dotfiles directory.
run_makefile() {
  cd "$DOTFILES_DIR" || { echo "Failed to navigate to dotfiles directory."; exit 1; }
  echo "Running Makefile..."
  make || { echo "Make process failed."; exit 1; }
}

# Main script execution.
main() {
  ask_for_sudo
  update_macos
  install_xcode_cli_tools
  update_dotfiles_repo
  run_makefile
}

main "$@"
