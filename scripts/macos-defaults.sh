#!/usr/bin/env zsh

# Script to customize macOS Desktop & Dock settings

# Close any open System Preferences panes to prevent them from overriding settings
osascript -e 'tell application "System Preferences" to quit'

# Function to safely apply defaults
apply_default() {
    domain=$1
    key=$2
    type=$3
    value=$3
    if defaults read "$domain" "$key" &>/dev/null; then
        echo "Setting $domain $key to $value."
        defaults write "$domain" "$key" "$type" "$value"
    else
        echo "Setting for $domain $key not found."
    fi
}

###############################################################################
# Desktop & Dock                                                              #
###############################################################################

echo "Configuring Desktop & Dock settings..."

# Size of Dock items
apply_default 'com.apple.dock' 'tilesize' -int 36

# Dock magnification
apply_default 'com.apple.dock' 'magnification' -bool true
apply_default 'com.apple.dock' 'largesize' -int 100

# Restart affected applications to apply changes
echo "Restarting affected applications..."
for app in "Dock" "Finder"; do
    killall "$app" &>/dev/null && echo "Restarted $app"
done

echo "⚠️ Note: Some of these changes require a restart to take effect. 🚀"
