#!/usr/bin/env bash

defaults write com.googlecode.iterm2 PrefsCustomFolder "$(DOTFILES_DIR)/files"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile_selection -bool true