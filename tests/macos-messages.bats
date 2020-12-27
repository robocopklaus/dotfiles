#!/usr/bin/env bats

@test "Test if spell check is enabled in Messages" {
  result="$(defaults read com.apple.messages.text SpellChecking)"
  [ "$result" -eq 2 ]
}
