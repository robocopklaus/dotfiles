#!/usr/bin/env bats

@test "Test if three finger drag is enabled (1)" {
  result="$(defaults read com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag)"
  [ "$result" -eq 1 ]
}

@test "Test if three finger drag is enabled (2)" {
  result="$(defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag)"
  [ "$result" -eq 1 ]
}
