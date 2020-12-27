# Shell tools
brew "zsh-autosuggestions"
brew "zsh-completions"
brew "zsh-syntax-highlighting"

# Programming language prerequisites and package managers
brew "git"

# Terminal
cask "iterm2"

# brew "bats-core" unless ENV['GITHUB_ACTION'].nil?

if ENV.include?('GITHUB_ACTION')
  brew "bats-core"
end