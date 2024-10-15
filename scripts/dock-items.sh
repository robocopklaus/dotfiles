#!/usr/bin/env zsh

# Script to customize the macOS Dock using dockutil

# Check if dockutil is installed
if ! command -v dockutil &> /dev/null; then
    echo "dockutil is not installed. Please install dockutil first."
    exit 1
fi

# Clear existing Dock items
dockutil --no-restart --remove all

# Music applications
echo "Adding Music applications to Dock..."

dockutil --no-restart --add "/System/Applications/Music.app"
dockutil --no-restart --add "/Applications/Spotify.app"
dockutil --no-restart --add '' --type small-spacer --section apps

# Browser applications
echo "Adding Browser applications to Dock..."

dockutil --no-restart --add "/System/Cryptexes/App/System/Applications/Safari.app"
dockutil --no-restart --add "/Applications/Google Chrome.app"
dockutil --no-restart --add '' --type small-spacer --section apps

# Communication applications
echo "Adding Communication applications to Dock..."

dockutil --no-restart --add "/System/Applications/Mail.app"
dockutil --no-restart --add "/Applications/Mimestream.app"
dockutil --no-restart --add "/Applications/ChatGPT.app"
dockutil --no-restart --add "/Applications/Slack.app"
dockutil --no-restart --add "/System/Applications/Messages.app"
dockutil --no-restart --add '' --type small-spacer --section apps

# Productivity applications
echo "Adding Productivity applications to Dock..."

dockutil --no-restart --add "/Applications/Notion.app"
dockutil --no-restart --add "/System/Applications/GCal for Google Calendar.app"
dockutil --no-restart --add "/System/Applications/Calendar.app"
dockutil --no-restart --add '' --type small-spacer --section apps

# Development tools
echo "Adding Development tools to Dock..."

dockutil --no-restart --add "/Applications/Visual Studio Code.app"
dockutil --no-restart --add "/Applications/iTerm.app"
dockutil --no-restart --add '' --type small-spacer --section apps

# System Preferences
echo "Adding System Preferences to Dock..."

dockutil --no-restart --add "/System/Applications/System Settings.app"

# Dock folders
echo "Adding Folders to Dock..."

dockutil --no-restart --add "/Applications" --view auto --display folder --sort name
dockutil --no-restart --add '~/Downloads' --view auto --display folder --sort dateadded

# Restart Dock to apply changes
echo "Restarting Dock to apply changes..."

killall Dock

echo "Dock customization complete. 🚀"
