#!/usr/bin/env zsh

# Script to customize macOS settings, including sound, accessibility, and dock preferences
# Information is based on macOS defaults (https://macos-defaults.com) and experimenting with PListWatcher (https://github.com/catilac/plistwatch)

# Function to safely apply defaults
apply_default() {
    local domain=$1
    local key=$2
    local type=$3
    local value=$4

    echo "Setting $domain $key to $value."
    if defaults write "$domain" "$key" "$type" "$value"; then
        echo "Successfully set $key."
    else
        echo "Failed to set $key."
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
# Appearance                                                                  #
###############################################################################

echo "Configuring Appearance settings..."

apply_default 'NSGlobalDomain' 'AppleInterfaceStyleSwitchesAutomatically' -bool true

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
# Control Center                                                              #
###############################################################################

echo "Configuring Control Center settings..."

# Bluetooth
apply_default 'com.apple.controlcenter' 'NSStatusItem Visible Bluetooth' -bool true

# Now Playing
apply_default 'com.apple.controlcenter' 'NSStatusItem Visible NowPlaying' -bool false

###############################################################################
# Desktop & Dock                                                              #
###############################################################################

echo "Configuring Desktop & Dock settings..."

# Apply Desktop & Dock settings
apply_default 'com.apple.dock' 'tilesize' -int 36
apply_default 'com.apple.dock' 'magnification' -bool true
apply_default 'com.apple.dock' 'largesize' -int 100
apply_default 'com.apple.dock' 'show-recents' -bool false

apply_default 'com.apple.WindowManager' 'EnableTilingByEdgeDrag' -bool false

###############################################################################
# Keyboard                                                                    #
###############################################################################

echo "Configuring Keyboard settings..."

apply_default 'NSGlobalDomain' 'KeyRepeat' -int 2
apply_default 'NSGlobalDomain' 'InitialKeyRepeat' -int 15
apply_default 'NSGlobalDomain' 'NSAutomaticSpellingCorrectionEnabled' -bool false
apply_default 'NSGlobalDomain' 'NSAutomaticCapitalizationEnabled' -bool false
apply_default 'NSGlobalDomain' 'AppleKeyboardUIMode' -int 2

###############################################################################
# Trackpad                                                                    #
###############################################################################

echo "Configuring Trackpad settings..."

# Enable Tap to click and set tracking speed
apply_default 'com.apple.AppleMultitouchTrackpad' 'Clicking' -bool true
apply_default 'com.apple.driver.AppleBluetoothMultitouch.trackpad' 'Clicking' -bool true
apply_default 'NSGlobalDomain' 'com.apple.trackpad.scaling' -float 2.5

# Enable App Exposé
apply_default 'com.apple.dock' 'showAppExposeGestureEnabled' -bool true

###############################################################################
# Other                                                                       #
###############################################################################

echo "Configuring Other settings..."

# Disable `Reopen windows when logging back in`
apply_default 'com.apple.loginwindow' 'TALLogoutSavesState' -bool false

# Flash clock time separators
apply_default 'com.apple.menuextra.clock' 'FlashDateSeparators' -bool true

###############################################################################
# Finder                                                                      #
###############################################################################

echo "Configuring Finder settings..."

# Keep folders on top, set new window target to home, hide external drives, etc.
apply_default 'com.apple.finder' '_FXSortFoldersFirst' -bool true
apply_default 'com.apple.finder' 'NewWindowTarget' -string "PfHm"
apply_default 'com.apple.finder' 'NewWindowTargetPath' -string "file://${HOME}"
apply_default 'com.apple.finder' 'ShowExternalHardDrivesOnDesktop' -bool false
apply_default 'com.apple.finder' 'ShowRecentTags' -bool false
apply_default 'com.apple.finder' 'FXDefaultSearchScope' -string "SCcf"
apply_default 'com.apple.finder' 'ShowPathbar' -bool true
apply_default 'com.apple.finder' 'ShowStatusBar' -bool true
apply_default 'com.apple.finder' 'FXPreferredViewStyle' -string "clmv"

# Unhide Library folder
if [[ -d ~/Library ]]; then
    chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library
fi

# Show item info near icons on the desktop
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist

# Sort items by name on the desktop
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy name" ~/Library/Preferences/com.apple.finder.plist

###############################################################################
# Calendar                                                                    #
###############################################################################

echo "Configuring Calendar settings..."

apply_default 'com.apple.iCal' 'Show Week Numbers' -bool true
apply_default 'com.apple.iCal' 'CalendarSidebarShown' -bool true

###############################################################################
# Music                                                                       #
###############################################################################

echo "Configuring Music settings..."

apply_default 'com.apple.Music' 'userWantsPlaybackNotifications' -bool false

###############################################################################
# Restart affected applications                                               #
###############################################################################

echo "Restarting affected applications..."
for app in "Music" "Calendar" "Dock" "Finder" "SystemUIServer" "cfprefsd"; do
    if pgrep "$app" &>/dev/null; then
        if killall "$app" &>/dev/null; then
            echo "Restarted $app"
        else
            echo "Failed to restart $app"
        fi
    else
        echo "$app is not running, no need to restart."
    fi
done

echo "⚠️ Note: Some of these changes require a restart to take effect. 🚀"
