#!/usr/bin/env bats

@test "Test if feedback is enabled when volume is changed" {
  result="$(defaults read NSGlobalDomain com.apple.sound.beep.feedback)"
  [ "$result" -eq 1 ]
}

@test "Test if startup sound is disabled" {
  result="$(nvram StartupMute | sed 's/StartupMute //')"
  [ "$result" = "%01" ]
}
