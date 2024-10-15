#!/usr/bin/env zsh

# Script to customize the macOS Dock using dockutil

# Check if dockutil is installed
if ! command -v dockutil &> /dev/null; then
    echo "dockutil is not installed. Please install dockutil first."
    exit 1
fi

# Function to add applications to the Dock
add_apps_to_dock() {
    local category=$1
    shift
    local apps=("$@")

    echo "Adding $category applications to Dock..."
    for app in "${apps[@]}"; do
        if ! dockutil --no-restart --add "$app"; then
            echo "Failed to add $app to Dock."
        fi
    done
    dockutil --no-restart --add '' --type small-spacer --section apps
}

# Clear existing Dock items
dockutil --no-restart --remove all

# Define application categories and their paths
music_apps=(
    "/System/Applications/Music.app"
    "/Applications/Spotify.app"
)

browser_apps=(
    "/System/Cryptexes/App/System/Applications/Safari.app"
    "/Applications/Google Chrome.app"
)

communication_apps=(
    "/System/Applications/Mail.app"
    "/Applications/Mimestream.app"
    "/Applications/Slack.app"
    "/System/Applications/Messages.app"
)

productivity_apps=(
    "/Applications/ChatGPT.app"
    "/Applications/Notion.app"
    "/System/Applications/GCal for Google Calendar.app"
    "/System/Applications/Calendar.app"
)

development_tools=(
    "/Applications/Visual Studio Code.app"
    "/Applications/iTerm.app"
)

system_preferences=(
    "/System/Applications/System Settings.app"
)

# Add applications to the Dock
add_apps_to_dock "Music" "${music_apps[@]}"
add_apps_to_dock "Browser" "${browser_apps[@]}"
add_apps_to_dock "Communication" "${communication_apps[@]}"
add_apps_to_dock "Productivity" "${productivity_apps[@]}"
add_apps_to_dock "Development" "${development_tools[@]}"
add_apps_to_dock "System Preferences" "${system_preferences[@]}"

# Add folders to the Dock
echo "Adding Folders to Dock..."
dockutil --no-restart --add "/Applications" --view auto --display folder --sort name
dockutil --no-restart --add '~/Downloads' --view auto --display folder --sort dateadded

# Restart Dock to apply changes
echo "Restarting Dock to apply changes..."
killall Dock

echo "Dock customization complete. 🚀"
