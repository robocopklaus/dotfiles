#!/usr/bin/env bats

@test "Test if address book is sorted by first name" {
  result="$(defaults read com.apple.addressbook ABNameSortingFormat)"
  [ "$result" = "sortingFirstName sortingLastName" ]
}
