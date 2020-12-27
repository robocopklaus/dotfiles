#!/usr/bin/env bats

@test "Test if new Finder windows show home path (1)" {
  result="$(defaults read com.apple.finder NewWindowTarget)"
  [ "$result" = "PfHm" ]
}

@test "Test if new Finder windows show home path (2)" {
  result="$(defaults read com.apple.finder NewWindowTargetPath)"
  [ "$result" = "file://${HOME}" ]
}

@test "Test if external disks on the desktop are hidden" {
  result="$(defaults read com.apple.finder ShowExternalHardDrivesOnDesktop)"
  [ "$result" -eq 0 ]
}

@test "Test if recent tags are hidden" {
  result="$(defaults read com.apple.finder ShowRecentTags)"
  [ "$result" -eq 0 ]
}

@test "Test if search the current folder is enabled" {
  result="$(defaults read com.apple.finder FXDefaultSearchScope)"
  [ "$result" -eq "SCcf" ]
}

@test "Test if the path bar is shown" {
  result="$(defaults read com.apple.finder ShowPathbar)"
  [ "$result" -eq 1 ]
}

@test "Test if the status bar is shown" {
  result="$(defaults read com.apple.finder ShowStatusBar)"
  [ "$result" -eq 1 ]
}

@test "Test if column view is active" {
  result="$(defaults read com.apple.finder FXPreferredViewStyle)"
  [ "$result" -eq "clmv" ]
}

@test "Test if the ~/Library folder is not hidden" {
  result="$(ls -aOl ~/Library | sed -n 2p | grep -c hidden)"
  [ "$result" -eq 0 ]
}

@test "Test if item info near icons on the desktop is shown" {
  result="$(/usr/libexec/PlistBuddy -c "Print :DesktopViewSettings:IconViewSettings:showItemInfo" ~/Library/Preferences/com.apple.finder.plist)"
  [ "$result" = "true" ]
}

@test "Test if items on the desktop are sorted by name" {
  result="$(/usr/libexec/PlistBuddy -c "Print :DesktopViewSettings:IconViewSettings:arrangeBy" ~/Library/Preferences/com.apple.finder.plist)"
  [ "$result" = "name" ]
}