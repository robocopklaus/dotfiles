# ------------------------------
# Environment Setup
# ------------------------------

# Volta: JavaScript toolchains manager
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Homebrew environment setup
eval "$(/opt/homebrew/bin/brew shellenv)"

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
source $(brew --prefix)/opt/antidote/share/antidote/antidote.zsh
antidote load

# Load Powerlevel10k theme configuration if available
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
