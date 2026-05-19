# dotfiles

Personal macOS setup managed with [chezmoi](https://www.chezmoi.io/).

This repository is intended to rebuild the same development environment on my
MacBook Pro and Mac Studio.

## Install

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io/lb)" -- --use-builtin-git=true init --apply robocopklaus/dotfiles
```

This installs `chezmoi` into `~/.local/bin`, clones this repository into the
default source directory, and applies the managed files.

The install command uses chezmoi's built-in Git support so a fresh macOS system
can clone this repository before Xcode Command Line Tools are installed. The
first apply opens the Command Line Tools installer when needed, waits for it to
finish, installs Homebrew when needed, and then applies the `Brewfile`.

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
