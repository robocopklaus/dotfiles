#!/usr/bin/env zsh

# Script to customize macOS settings, including sound, accessibility, and dock preferences

# Function to safely apply defaults
apply_default() {
    domain=$1
    key=$2
    type=$3
    value=$4
    if defaults read "$domain" "$key" &>/dev/null; then
        echo "Setting $domain $key to $value."
        defaults write "$domain" "$key" "$type" "$value" && echo "Successfully set $key" || echo "Failed to set $key"
    else
        echo "Setting for $domain $key not found."
    fi
}

# Close any open System Preferences panes to prevent overriding settings
osascript -e 'tell application "System Preferences" to quit'

###############################################################################
# Sound                                                                       #
###############################################################################

echo "Configuring Sound settings..."

# Play feedback when volume is changed
apply_default 'NSGlobalDomain' 'com.apple.sound.beep.feedback' -bool true

# Don't play sound on startup (requires sudo)
if [[ $EUID -ne 0 ]]; then
    echo "⚠️ Changing startup sound setting requires sudo privileges."
else
    echo "Disabling startup sound..."
    sudo nvram StartupMute=%01
fi

###############################################################################
# Accessibility                                                               #
###############################################################################

echo "Configuring Accessibility settings..."

# Enable three finger drag
apply_default 'com.apple.AppleMultitouchTrackpad' 'Dragging' -bool true
apply_default 'com.apple.AppleMultitouchTrackpad' 'TrackpadThreeFingerDrag' -bool true
apply_default 'com.apple.driver.AppleBluetoothMultitouch.trackpad' 'Dragging' -bool true
apply_default 'com.apple.driver.AppleBluetoothMultitouch.trackpad' 'TrackpadThreeFingerDrag' -bool true

###############################################################################
# Desktop & Dock                                                              #
###############################################################################

echo "Configuring Desktop & Dock settings..."

# Apply Desktop & Dock settings
apply_default 'com.apple.dock' 'tilesize' -int 36
apply_default 'com.apple.dock' 'magnification' -bool true
apply_default 'com.apple.dock' 'largesize' -int 100
apply_default 'com.apple.dock' 'show-recents' -bool false
apply_default 'com.apple.dock' 'mineffect' -string 'suck'

# Restart affected applications to apply changes
echo "Restarting affected applications..."
for app in "Dock" "Finder"; do
    if pgrep "$app" &>/dev/null; then
        killall "$app" &>/dev/null && echo "Restarted $app"
    else
        echo "$app is not running, no need to restart."
    fi
done

echo "⚠️ Note: Some of these changes require a restart to take effect. 🚀"
