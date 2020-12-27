#!/usr/bin/env bats

@test "Test if Bluetooth icon is shown in menu bar" {
  result="$(defaults read com.apple.controlcenter \"NSStatusItem Visible Bluetooth\")"
  [ "$result" -eq 1 ]
}
