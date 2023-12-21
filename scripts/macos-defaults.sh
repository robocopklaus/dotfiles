#!/usr/bin/env zsh

# Script to customize macOS settings, including sound, accessibility, and dock preferences
# Information is based on macOS defaults (https://macos-defaults.com) and experimenting with PListWatcher (https://github.com/catilac/plistwatch)

# Function to safely apply defaults
apply_default() {
    domain=$1
    key=$2
    type=$3
    value=$4

    # Check if the key already exists
    if defaults read "$domain" "$key" &>/dev/null; then
        echo "Setting $domain $key to $value."
        defaults write "$domain" "$key" "$type" "$value" && echo "Successfully set $key." || echo "Failed to set $key."
    else
        # Key does not exist - decide to create or skip
        echo "Key $key not found in $domain."
        read -p "Do you want to create it? [y/N] " response
        case "$response" in
            [Yy]*)
                echo "Creating $key and setting to $value."
                defaults write "$domain" "$key" "$type" "$value" && echo "Successfully created and set $key." || echo "Failed to create $key."
                ;;
            *)
                echo "Skipped setting $key."
                ;;
        esac
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
# Safari                                                                      #
###############################################################################

echo "Configuring Safari settings..."

# Show full website address
apply_default 'com.apple.Safari' 'ShowFullURLInSmartSearchField' -bool true

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



# Restart affected applications to apply changes
echo "Restarting affected applications..."
for app in "Music" "Calendar" "Dock" "Finder" "SystemUIServer" "Safari" "cfprefsd"; do
    if pgrep "$app" &>/dev/null; then
        killall "$app" &>/dev/null && echo "Restarted $app"
    else
        echo "$app is not running, no need to restart."
    fi
done

echo "⚠️ Note: Some of these changes require a restart to take effect. 🚀"
