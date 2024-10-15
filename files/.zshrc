# ------------------------------
# Environment Setup
# ------------------------------

# Volta: JavaScript toolchains manager
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Homebrew environment setup
if command -v brew &> /dev/null; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ------------------------------
# Zsh Customizations
# ------------------------------

# Powerlevel10k: A fast Zsh prompt
# Enable instant prompt, should be near the top of the file
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Antidote: A plugin manager for Zsh
# Loads Antidote and its plugins
if command -v brew &> /dev/null; then
  source "$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh"
  antidote load
fi

# Load Powerlevel10k theme configuration if available
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
