# .files

## 🚀 A development setup in just a few minutes without the hassle

Got a new 💻 or planning a clean install of the latest macOS but short on time to set everything up? Meet **.files**!

**.files** is a collection of configuration files (dotfiles) plus an automated setup to install all the apps and tools you need in no time.

![Screenshot](https://raw.githubusercontent.com/robocopklaus/dotfiles/main/screenshot.png)

## 🤖 Automated installation

⚠️ Please backup your current settings. They may be overwritten!

After installing macOS, copy & paste this line into the terminal:

```sh
curl -fsSL https://raw.githubusercontent.com/robocopklaus/dotfiles/main/scripts/remote-install.sh | bash
```

## 🐢 Manual installation

⚠️ Please backup your current settings. They may be overwritten!

💡 macOS Command Line Tools are **required**. Install them with:

```sh
xcode-select --install
```

1. Clone this repo:

  ```sh
  git clone git@github.com:robocopklaus/dotfiles.git
  ```

2. Install:

  ```sh
  make install
  ```

## 🧐 What's included?

### Programming language utilities and package managers

- **[Homebrew](https://github.com/Homebrew/brew)**: Simplifies software installation on macOS and Linux.
- **[Git](https://github.com/git/git)**: Often more up-to-date than the version shipped with macOS.
- **[Volta](https://github.com/volta-cli/volta)**: Manages JavaScript command-line tools like `node`, `npm`, and `yarn`.

### Terminal Tools

- **[iTerm2](https://github.com/gnachman/iTerm2)**: A fast and visually appealing Terminal replacement.
- **[Antidote](https://github.com/mattmc3/antidote)**: A faster and simpler Zsh plugin manager.
- **[Command Not Found](https://github.com/Homebrew/homebrew-command-not-found)**: Suggests commands to install missing packages.
- **[z - jump around](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/z)**: Tracks and quickly accesses your most visited directories.
- **[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)**: Suggests commands as you type.
- **[zsh-completions](https://github.com/zsh-users/zsh-completions)**: Additional completion definitions for Zsh.
- **[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)**: Syntax highlighting for Zsh.

### DevOps

- **[Docker](https://www.docker.com)**: Packages software into containers for quick deployment and scaling.

### IDE

- **[Visual Studio Code](https://github.com/microsoft/vscode)**: Popular developer environment tool.
- **[Material Neutral Theme](https://github.com/bernardodsanderson/material-neutral-theme)**: VS Code theme based on Material Design.
- **[Material Icon Theme](https://github.com/PKief/vscode-material-icon-theme)**: Brings Material Design icons to VS Code.
- **[Docker for Visual Studio Code](https://github.com/microsoft/vscode-docker)**: Manages containerized applications from VS Code.
- **[Rainbow CSV](https://github.com/mechatroner/vscode_rainbow_csv)**: Highlights CSV and TSV files in different colors.
- **[Dotenv](https://github.com/mikestead/vscode-dotenv)**: Support for `.env` files.
- **[GitHub Copilot](https://github.com/github/copilot)**: AI pair programmer.
- **[GitHub Copilot Chat](https://github.com/github/copilot-chat)**: Chat with GitHub Copilot.
- **[Indent Rainbow](https://github.com/oderwat/vscode-indent-rainbow)**: Makes indentation more readable.

### Productivity Tools

- **[1Password](https://1password.com)**: Securely stores passwords and sensitive information.
- **[Google Drive](https://www.google.com/drive/download/)**: Access Google Drive files without a web browser.
- **[Notion](https://www.notion.so)**: All-in-one workspace for databases, kanban boards, wikis, and more.
- **[Slack](https://slack.com)**: Channel-based messaging platform.
- **[Clockify](https://clockify.me)**: Time tracking software.
- **[Herd](https://herd.laravel.com)**: A one-click PHP development environment with zero dependencies and zero headaches.
- **[Kap](https://getkap.co)**: Open-source screen recorder.
- **[Postman](https://www.postman.com)**: API development environment.
- **[Sketch](https://www.sketch.com)**: Digital design toolkit.
- **[TablePlus](https://tableplus.com)**: Modern, native tool for database management.
- **[WhatsApp](https://www.whatsapp.com)**: Messaging app.
- **[Home Assistant](https://www.home-assistant.io)**: Open-source home automation platform.
- **[Mimestream](https://mimestream.com)**: Native macOS email client for Gmail.
- **[ChatGPT](https://chat.openai.com)**: AI chatbot.

### Browsers

- **[Chrome](https://www.google.com/chrome/)**: Browser with the highest market share worldwide.
- **[Firefox Developer Edition](https://www.mozilla.org/firefox/developer/)**: Tailored for web developers.

### Audio & Video

- **[IINA](https://github.com/iina/iina)**: Lightweight media player based on mpv.
- **[Spotify](https://www.spotify.com)**: Digital music service.

### macOS utilities

- **[Dockutil](https://github.com/kcrawford/dockutil)**: Command line utility for managing macOS dock items.
- **[mas-cli](https://github.com/mas-cli/mas)**: Command line interface for the Mac App Store.
- **[Finicky](https://github.com/johnste/finicky)**: Sets up rules to decide which browser opens for each link.

## References

- [Makefile for your dotfiles](https://polothy.github.io/post/2018-10-09-makefile-dotfiles/) - Mark Nielsen
- [Mathias’s dotfiles](https://github.com/mathiasbynens/dotfiles) - Mathias Bynens
- [.files](https://github.com/webpro/dotfiles) - Lars Kappert
- [Dotfiles](https://github.com/martijngastkemper/dotfiles) - Martijn Gastkemper
- [Matt's MacOS dotfiles](https://github.com/mattorb/dotfiles) - Matt Smith
- [macOS defaults list](https://macos-defaults.com) - Yann Bertrand

