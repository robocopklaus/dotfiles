# dotfiles

Personal macOS setup managed with [chezmoi](https://www.chezmoi.io/).

This repository is intended to rebuild the same development environment on my
MacBook Pro and Mac Studio.

## Install

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io/lb)" -- -- --use-builtin-git=true init --apply robocopklaus/dotfiles
```

This installs `chezmoi` into `~/.local/bin`, clones this repository into the
default source directory, and applies the managed files.

The install command uses chezmoi's built-in Git support so a fresh macOS system
can clone this repository before Xcode Command Line Tools are installed. The
first apply opens the Command Line Tools installer when needed, waits for it to
finish, installs Homebrew when needed, applies the `Brewfile` including Codex
CLI, and installs Claude Code with its native installer when needed.

Zsh plugins are managed with Antidote via `~/.zsh_plugins.txt`, with zoxide
handling directory jumps. Only selected Oh My Zsh plugins are loaded, not the
full Oh My Zsh framework.

Git commits and tags are configured for SSH signing with 1Password. On a fresh
Mac, sign in to 1Password and enable the 1Password SSH agent (Settings →
Developer → "Use the SSH agent"). Register the public key in GitHub twice —
under **SSH keys** (for `git push` over SSH) and under **SSH signing keys** (for
commit verification). The `~/.ssh/config` that points `ssh` at the 1Password
agent socket is managed by chezmoi. Local signature verification uses
`~/.config/git/allowed_signers` and can be checked with:

```bash
git log --show-signature
```

If `chezmoi` is already installed:

```bash
chezmoi --use-builtin-git=true init --apply robocopklaus/dotfiles
```

## Daily Use

```bash
chezmoi status
chezmoi diff
chezmoi apply
chezmoi update -v
chezmoi cd
```

The chezmoi source directory uses the default path:

```text
~/.local/share/chezmoi
```

## Iteration

Start with the minimum setup, adjust the Mac normally, then add files back to
chezmoi when they are worth keeping:

```bash
chezmoi add ~/.zshrc
chezmoi cd
git status
git commit -m "chore: update shell config"
git push
```

Secrets are not stored in Git. Use 1Password for tokens and keys.

## Validation

CI is the source of truth for repository validation. See
[.github/workflows/ci.yml](.github/workflows/ci.yml).
