#!/usr/bin/env bats

@test "Test if Apple's personalized ads are turned off" {
  result="$(defaults read com.apple.AdLib allowApplePersonalizedAdvertising)"
  [ "$result" -eq 0 ]
}
