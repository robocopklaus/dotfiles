#!/usr/bin/env bats

@test "Test if icon size of Dock items is 36px" {
  result="$(defaults read com.apple.dock tilesize)"
  [ "$result" -eq 36 ]
}

@test "Test if Dock magnification is enabled" {
  result="$(defaults read com.apple.dock magnification)"
  [ "$result" -eq 1 ]
}

@test "Test if magnified icon size of Dock items is 90px" {
  result="$(defaults read com.apple.dock largesize)"
  [ "$result" -eq 36 ]
}

@test "Test if recent applications in Dock are disabled" {
  result="$(defaults write com.apple.dock show-recents)"
  [ "$result" -eq 0 ]
}

@test "Test if animation effect for minimizing windows is set to suck" {
  result="$(defaults read com.apple.dock mineffect)"
  [ "$result" -eq "suck" ]
}