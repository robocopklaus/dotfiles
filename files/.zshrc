#autoload -Uz compinit
#compinit

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Kubernetes
#source <(kubectl completion zsh)

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# eval "$(pyenv init -)"

# Volta
export VOLTA_HOME="$HOME/.volta"
#export PATH="/opt/homebrew/opt/openjdk/bin:/usr/local/sbin:$VOLTA_HOME/bin:$PATH"
export PATH="/usr/local/sbin:$VOLTA_HOME/bin:$PATH"

# SOPS
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

# Load Antigen
source $(brew --prefix)/share/antigen/antigen.zsh

# Load Antigen configurations
antigen init $HOME/.antigenrc

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
