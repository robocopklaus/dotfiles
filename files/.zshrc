# ------------------------------
# Environment Setup
# ------------------------------

# Volta: JavaScript toolchains manager
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Homebrew environment setup
eval "$(/opt/homebrew/bin/brew shellenv)"

# ------------------------------
# Aliases
# ------------------------------
alias git-prune-branches="npx -y git-removed-branches -p --force"
alias npm-check-updates="npx -y npm-check-updates -i --format group"

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
  # source antidote
  source "$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh"
  # initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
  antidote load
fi

# Load Powerlevel10k theme configuration if available
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
