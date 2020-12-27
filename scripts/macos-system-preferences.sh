#!/usr/bin/env bash

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

###############################################################################
# General                                                                     #
###############################################################################

# Set number of recent items (Documents, Apps, and Servers)
for category in 'applications' 'documents' 'servers'; do
  /usr/bin/osascript -e "tell application \"System Events\" to tell appearance preferences to set recent $category limit to 5"
done

###############################################################################
# Dock & Menu Bar                                                             #
###############################################################################

# Set the icon size of Dock items to 36px
defaults write com.apple.dock tilesize -int 36

# Dock magnification
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 90

# Don’t show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Minimize windows using hidden suck animation effect
defaults write com.apple.dock mineffect -string suck

###############################################################################
# Accessibility                                                               #
###############################################################################

# Enable three finger drag
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

###############################################################################
# Security & Privacy                                                          #
###############################################################################

# Apple Advertising
# Turn off Personalized Ads
defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false

###############################################################################
# Bluetooth                                                                   #
###############################################################################

# Show Bluetooth in menu bar
defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true

###############################################################################
# Sound                                                                       #
###############################################################################

# Play feedback when volume is changed
defaults write NSGlobalDomain com.apple.sound.beep.feedback -bool true

# Don't play sound on startup
sudo nvram StartupMute=%01

###############################################################################
# Keyboard                                                                    #
###############################################################################

# Set the key repeat rate to fast
defaults write NSGlobalDomain KeyRepeat -int 2

# Set Delay Until Repeat to short
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Set Touch Bar to show Expanded Control Strip
defaults write com.apple.touchbar.agent PresentationModeGlobal fullControlStrip

# Do not correct spelling automatically
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Do not capitalize words automatically
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Use keyboard navigation to move focus between controls
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

###############################################################################
# Trackpad                                                                    #
###############################################################################

# Enable Tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Tracking speed
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2.5

# Enable App Exposé
defaults write com.apple.dock showAppExposeGestureEnabled -bool true

###############################################################################
# Other                                                                       #
###############################################################################

# Disable `Reopen windows when logging back in`
defaults write com.apple.loginwindow TALLogoutSavesState -bool false

###############################################################################
# Finder                                                                      #
###############################################################################

# New Finder windows show home path
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"

# Do not show external disks on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false

# Don't show recent tags
defaults write com.apple.finder ShowRecentTags -bool false

# When performing a search search the current folder
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Show Path Bar
defaults write com.apple.finder ShowPathbar -bool true

# Show Status Bar
defaults write com.apple.finder ShowStatusBar -bool true

# View as Columns
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Show the ~/Library folder
chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library

# Show item info near icons on the desktop
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist

# Sort items by name on the desktop
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy name" ~/Library/Preferences/com.apple.finder.plist

###############################################################################
# Address Book                                                                #
###############################################################################

# Sort by first name
defaults write com.apple.addressbook ABNameSortingFormat -string "sortingFirstName sortingLastName"

###############################################################################
# Calendar                                                                    #
###############################################################################

# Show week numbers
defaults write com.apple.iCal "Show Week Numbers" -bool true

# Show Calendar List
defaults write com.apple.iCal CalendarSidebarShown -bool true

###############################################################################
# Messages                                                                    #
###############################################################################

# Check spelling while typing
defaults write com.apple.messages.text SpellChecking -int 2


pkill "Touch Bar agent"

for app in "Calendar" \
           "cfprefsd" \
           "Contacts" \
           "ControlStrip" \
           "Dock" \
           "Finder" \
           "Messages"; do
           killall "${app}" &> /dev/null
done

echo "⚠️ Note: Some of these changes require a restart to take effect. 🚀"