#!/usr/bin/env bats

@test "Test if volta is installed" {
  [ command -v brew >/dev/null ]
}