# The inventory's entries, read from its text on stdin. The one place the entry shape is
# known: a kind keyword at column zero, then a double-quoted name, and for an App Store
# entry the id after it. Homebrew offers no filter of its own, so every reader of the
# inventory — the Packages phase, `drift`, the lint tier and the tests — asks here
# rather than writing the shape a fifth time.
#
# Only the text is read, never a path: each caller inlines the inventory it was rendered
# with, because `run_onchange_` hashes that text (ADR 0005), and which files are in it is
# the caller's condition to state.

# The names of one kind of entry, one per line: `tap`, `brew` or `cask`. For `mas`, each
# line is `id name`, the id first because a name may contain spaces.
inventory_entries() {
  case $1 in
    tap | brew | cask) sed -n "s/^$1 \"\\([^\"]*\\)\".*/\\1/p" ;;
    mas) sed -n 's/^mas "\([^"]*\)", id: \([0-9][0-9]*\).*/\2 \1/p' ;;
    *)
      printf 'inventory_entries: no entry kind %s\n' "$1" >&2
      return 2
      ;;
  esac
}

# Homebrew 7 refuses to load a formula or cask from a third-party tap until the tap is
# trusted, and `brew bundle` reports the refusal per entry and carries on — so a missing
# decision arrives looking like a flaky partial install.
#
# Which taps are trusted is derived from the `tap` entries, not named a second time:
# declaring a tap is already the statement that its formulae may be installed and run.
# Trusting is idempotent and does not require the tap to exist yet. Tapping is left to
# the caller — `brew bundle` taps as it goes, and the lint tier taps to ask about entries.
#
# The first failure is returned by hand, because the Packages phase runs this as a step,
# where `set -e` does not reach.
inventory_trust_taps() {
  local taps tap
  taps=$(inventory_entries tap)
  for tap in $taps; do
    brew trust --tap "$tap" || return
  done
}
