#!/usr/bin/env bash

dockutil --no-restart --remove all

# Music
dockutil --no-restart --add "/System/Applications/Music.app"
dockutil --no-restart --add "/Applications/Spotify.app"
dockutil --no-restart --add '' --type small-spacer --section apps

# Browsers
dockutil --no-restart --add "/Applications/Safari.app"
dockutil --no-restart --add "/Applications/Google Chrome.app"
dockutil --no-restart --add "/Applications/Firefox Developer Edition.app"
dockutil --no-restart --add '' --type small-spacer --section apps

# Communication
dockutil --no-restart --add "/System/Applications/Mail.app"
dockutil --no-restart --add "/Applications/Mimestream.app"
dockutil --no-restart --add "/Applications/Slack.app"
dockutil --no-restart --add "/System/Applications/Messages.app"
dockutil --no-restart --add '' --type small-spacer --section apps

# Productivity
dockutil --no-restart --add "/Applications/Notion.app"
dockutil --no-restart --add "/System/Applications/Calendar.app"
dockutil --no-restart --add '' --type small-spacer --section apps

# Dev
dockutil --no-restart --add "/Applications/Visual Studio Code.app"
dockutil --no-restart --add "/Applications/iTerm.app"
dockutil --no-restart --add '' --type small-spacer --section apps

# System preferences
dockutil --no-restart --add "/System/Applications/System Settings.app"

# Folders
dockutil --no-restart --add "/Applications" --view auto --display folder --sort name
dockutil --no-restart --add '~/Downloads' --view auto --display folder --sort dateadded

killall Dock