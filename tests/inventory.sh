#!/bin/bash
# The inventory's reader, against a literal inventory.
#
# Usage: tests/inventory.sh <rendered lib/inventory.sh>
#
# Every other reader of the inventory — the Packages phase, `drift`, the lint tier, and
# tests/drift.sh building its machine — goes through this one, so this is the one place
# the entry shape is asserted rather than assumed. The fixture is literal on purpose: read
# out of the real Brewfile, a reader that dropped an entry would drop it from the
# expectation too and pass.

set -uo pipefail

lib=${1:?usage: tests/inventory.sh <rendered lib/inventory.sh>}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
mkdir -p "$root/bin"

fail=0
check() {
  local name=$1 expected=$2 actual=$3
  if [ "$expected" = "$actual" ]; then
    printf 'ok   %s\n' "$name"
  else
    printf 'FAIL %s\n  expected: %s\n  actual:   %s\n' "$name" "$expected" "$actual"
    fail=1
  fi
}

# Each kind, with the reason comment and the column alignment the real inventory carries,
# and the lines a reader must pass over: comments, a blank, an indented entry-like line
# and a keyword that only starts like one.
inventory='# Header comment naming no entry
tap "owner/tap"  # Backs the formula below

brew "plain"             # A formula
brew "with-options", args: ["HEAD"]  # A formula carrying options
cask "some-app"          # A cask
cask "other-app"         # Another; "quoted" words in a reason are not a name
mas "Pages", id: 361309726                     # One word
mas "GCal for Google Calendar", id: 1107163858 # Several, so the id goes first
  brew "indented"        # Not at column zero, so not an entry
brewery "lookalike"      # Not the keyword
# cask "commented-out"   # Not an entry'

entries() {
  # shellcheck disable=SC1090
  (source "$lib" && inventory_entries "$@" <<<"$inventory")
}

check 'the taps' 'owner/tap' "$(entries tap)"
check 'the formulae, options dropped' $'plain\nwith-options' "$(entries brew)"
check 'the casks, reasons dropped' $'some-app\nother-app' "$(entries cask)"
check 'the App Store entries, id first' \
  $'361309726 Pages\n1107163858 GCal for Google Calendar' "$(entries mas)"

entries formula >/dev/null 2>&1
check 'a kind the inventory does not spell is refused' 2 "$?"

# Trusting: every tap is handed to `brew trust`, and the first refusal stops the rest and
# is returned, since the Packages phase runs this as a step, where `set -e` does not reach.
cat >"$root/bin/brew" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"$BREW_LOG"
[ "$3" != "$BREW_REFUSES" ]
EOF
chmod +x "$root/bin/brew"

trust() {
  : >"$root/log"
  # shellcheck disable=SC1090
  (source "$lib" && BREW_LOG="$root/log" BREW_REFUSES=$1 PATH="$root/bin:$PATH" \
    inventory_trust_taps <<<"$2")
}

taps=$'tap "one/tap"  # First\ntap "two/tap"  # Second\nbrew "not-a-tap"  # Skipped'
trust none "$taps"
check 'every tap is trusted' 0 "$?"
check 'only the taps reach brew' $'trust --tap one/tap\ntrust --tap two/tap' "$(cat "$root/log")"

trust one/tap "$taps"
check 'a refused tap is returned' 1 "$?"
check 'nothing is trusted after a refusal' 'trust --tap one/tap' "$(cat "$root/log")"

trust none 'brew "only-formulae"  # No taps'
check 'an inventory without taps trusts nothing' '' "$(cat "$root/log")"

exit "$fail"
