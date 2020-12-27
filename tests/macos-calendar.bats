#!/usr/bin/env bats

@test "Test if calendar shows week numbers" {
  result="$(defaults read com.apple.iCal "Show Week Numbers")"
  [ "$result" -eq 1 ]
}

@test "Test if calendar shows calendar list" {
  result="$(defaults read com.apple.iCal CalendarSidebarShown)"
  [ "$result" -eq 1 ]
}