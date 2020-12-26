#!/usr/bin/env zsh

isCommandAvailable() {
  if command -v $1 >/dev/null; then
    return
  else
    false
  fi
}

###############################################################################
# Homebrew                                                                    #
###############################################################################

if ! isCommandAvailable brew; then
  echo "Installing Homebrew..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi
