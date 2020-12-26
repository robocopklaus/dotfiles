#!/usr/bin/env zsh

###############################################################################
# Homebrew                                                                    #
###############################################################################

if ! command -v brew >/dev/null; then
  echo "Installing Homebrew..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi