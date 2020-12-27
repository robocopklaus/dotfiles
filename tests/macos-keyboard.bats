#!/usr/bin/env bats

@test "Test if the key repeat rate is set to fast" {
  result="$(defaults read NSGlobalDomain KeyRepeat)"
  [ "$result" -eq 2 ]
}

@test "Test if delay until repeat is set to short" {
  result="$(defaults read NSGlobalDomain InitialKeyRepeat)"
  [ "$result" -eq 15 ]
}

@test "Test if Touch Bar is set to show Expanded Control Strip" {
  result="$(defaults read com.apple.touchbar.agent PresentationModeGlobal)"
  [ "$result" = "fullControlStrip" ]
}

@test "Test if automatic spelling correction is disabled" {
  result="$(defaults read NSGlobalDomain NSAutomaticSpellingCorrectionEnabled)"
  [ "$result" -eq 0 ]
}

@test "Test if automatic word capitalization is disabled" {
  result="$(defaults read NSGlobalDomain NSAutomaticCapitalizationEnabled)"
  [ "$result" -eq 0 ]
}

@test "Test if keyboard navigation to move focus between controls is enabled" {
  result="$(defaults read NSGlobalDomain AppleKeyboardUIMode)"
  [ "$result" -eq 3 ]
}