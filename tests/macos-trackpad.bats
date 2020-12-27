#!/usr/bin/env bats

@test "Test if tap to click is enabled (1)" {
  result="$(defaults read com.apple.AppleMultitouchTrackpad Clicking)"
  [ "$result" -eq 1 ]
}

@test "Test if tap to click is enabled (2)" {
  result="$(defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking)"
  [ "$result" -eq 1 ]
}

@test "Test if tracking speed is set to 2.5" {
  result="$(defaults read NSGlobalDomain com.apple.trackpad.scaling)"
  [ "$result" -eq 2.5 ]
}

@test "Test if App Exposé is enabled" {
  result="$(defaults read com.apple.dock showAppExposeGestureEnabled)"
  [ "$result" -eq 1 ]
}