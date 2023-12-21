# macOS Environment Setup

This repository contains scripts and a Makefile to automate the setup and customization of a macOS environment. It includes Homebrew package management, dotfiles configuration, Visual Studio Code extensions, and system preferences customization.

## Features

- **Automated Installation**: Streamlines the installation of Homebrew packages and casks.
- **macOS Customization**: Applies preferred system preferences and Dock items settings.
- **Visual Studio Code Extensions**: Manages the installation of necessary extensions.
- **Dotfiles Management**: Automates the setup of dotfiles through symbolic links.
- **Easy to Use**: Simplified installation and uninstallation process.

## Prerequisites

Before you begin, ensure you have met the following requirements:

- macOS operating system (ARM-based Macs supported).
- Homebrew is required but will be installed by the script if not present.

## Installation

To set up your macOS environment:

1. **Clone the Repository**:
```bash
  git clone https://github.com/your-username/macos-setup.git
  cd macos-setup
```

2. **Run the Makefile**:
```bash
  make all
```

## Customization

You can customize the setup by modifying the following:

- Homebrew Packages: Edit the BREW_PACKAGES variable in the Makefile.
- VS Code Extensions: Modify VS_CODE_EXTENSIONS in the Makefile.
- System Preferences: Adjust scripts in scripts/macos-defaults.sh.
- Dotfiles: Add your dotfiles in the files directory.

## Uninstallation

To uninstall packages and revert changes:

```bash
  make uninstall-all
```
