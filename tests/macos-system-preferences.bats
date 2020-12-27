#!/usr/bin/env bats



@test "Test if icon size of Dock items is 36px" {
  result="$(defaults read com.apple.dock tilesize)"
  [ "$result" -eq 36 ]
}

@test "Test Dock magnification is enabled" {
  result="$(defaults read com.apple.dock magnification)"
  [ "$result" -eq 1 ]
}