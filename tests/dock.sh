#!/bin/bash
# The P6 Dock phase finds `dockutil` on a machine whose shell has never loaded Homebrew.
#
# `dockutil` is a formula, so it lives under Homebrew's prefix, which is on PATH only once
# something has run `brew shellenv`. On a routine apply the user's login shell already has,
# so a phase that forgets to load it works there and nowhere else: it surfaced on a
# bootstrap, as `dockutil: command not found` and `exit status 127` after P4 had installed
# it and P5 — which does load Homebrew — had just used it.
#
# So the oracle is not "the script ran". It is that the phase's preamble, run under a PATH
# with no Homebrew on it, leaves Homebrew's bin directory on PATH before the first Dock
# read. Only the preamble is run: everything after it reads and rebuilds the real Dock.
set -uo pipefail

script=${1:?usage: tests/dock.sh <rendered 61-dock.sh>}
# The line itself, unexpanded: it is matched as text, never run.
# shellcheck disable=SC2016
sentinel='expected=$(dock_expected_sequence)'

if ! grep -qxF "$sentinel" "$script"; then
  printf 'not ok - the first Dock read (%s) is not in %s\n' "$sentinel" "$script"
  exit 1
fi

preamble=$(mktemp)
trap 'rm -f "$preamble"' EXIT
# An exact line comparison, the same one the check above made, and not a pattern: a cut
# that misses runs the whole phase against the real Dock.
awk -v stop="$sentinel" '$0 == stop { exit } { print }' "$script" >"$preamble"

# The child shell expands "$1", not this one.
# shellcheck disable=SC2016
if env -i HOME="$HOME" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  bash -c 'source "$1" && command -v brew >/dev/null' _ "$preamble"; then
  printf 'ok - Homebrew is on PATH before the Dock phase calls dockutil\n'
else
  printf 'not ok - Homebrew is not on PATH before the Dock phase calls dockutil\n'
  exit 1
fi
