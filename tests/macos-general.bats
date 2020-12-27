#!/usr/bin/env bats

@test "Test if 'Reopen windows when logging back in' is disabled" {
  result="$(defaults read com.apple.loginwindow TALLogoutSavesState)"
  [ "$result" -eq 0 ]
}
