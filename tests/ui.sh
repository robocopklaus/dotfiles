#!/bin/bash
# The run's progress view, folded and unfolded (ADR 0017).
#
# Usage: tests/ui.sh [lib/ui.sh]
#
# CI has no terminal, so every phase it runs takes the unfolded path, and the folded one —
# the path every bootstrap at a desk takes — would never be exercised there at all. So it
# is driven here under a pseudo-terminal, with macOS `script`, alongside the plain run CI
# itself sees.
#
# The library carries no template directive, so the source file is what every phase
# renders it to and is read as it is.
set -uo pipefail

ui=${1:-$(cd "$(dirname "$0")/.." && pwd)/home/.chezmoitemplates/lib/ui.sh}

fail=0
check() {
  local name=$1 expected=$2 actual=$3
  if [ "$expected" = "$actual" ]; then
    printf 'ok   %s\n' "$name"
  else
    printf 'FAIL %s\n     expected: %s\n     actual:   %s\n' "$name" "$expected" "$actual"
    fail=1
  fi
}
says() {
  grep -qx -- "$2" <<<"$1"
  check "$3" 0 "$?"
}
silent() {
  grep -qx -- "$2" <<<"$1"
  check "$3" 1 "$?"
}

# Runs a snippet against the library under a pseudo-terminal. `script` echoes the end of
# its own input into the terminal as `^D` and two backspaces; that, the escapes and the
# terminal's carriage returns are stripped, so what is left is the lines a person sees.
tty_raw() {
  env -u CHEZMOI_VERBOSE "${@:2}" script -q /dev/null bash -c "source \"\$1\"; $1" _ "$ui" </dev/null
}
visible() {
  sed $'s/\\^D\b\b//g; s/\033\\[[0-9;]*[A-Za-z]//g; s/\r$//; s/.*\r//'
}

printf '\nFolded, under a terminal\n'
step='ui_step "a step that succeeds" echo hidden'
check 'a success is one line' 1 "$(tty_raw "$step" | tr -cd '\n' | wc -l | tr -d ' ')"
out=$(tty_raw "$step" | visible)
says "$out" '  ✓ a step that succeeds' 'and that line resolves to a tick'
silent "$out" 'hidden' "and the step's output is folded away"

out=$(tty_raw 'ui_step "a step that fails" sh -c "seq 1 30; exit 3"; echo "status $?"' | visible)
says "$out" '  ✗ a step that fails' 'a failure resolves to a cross'
says "$out" '    30' "and shows the last line of its output"
says "$out" '    11' 'and the twentieth from last'
silent "$out" '    10' 'and nothing before it'
says "$out" '    The whole output: chezmoi apply --verbose' 'and points at the whole of it'
says "$out" 'status 3' "and returns the command's status"

out=$(tty_raw 'ui_step "a step that would prompt" sh -c "[ ! -t 0 ]"' | visible)
says "$out" '  ✓ a step that would prompt' 'a folded step is not handed the terminal to read from'

out=$(tty_raw 'ui_step "a step under --verbose" echo shown' CHEZMOI_VERBOSE=1 | visible)
says "$out" 'shown' 'chezmoi apply --verbose unfolds it'

printf '\nUnfolded, without a terminal\n'
# shellcheck disable=SC1090
out=$(source "$ui" && {
  ui_header 'P0  a phase'
  ui_step 'a step that succeeds' echo shown
  ui_step 'a step that fails' sh -c 'echo also shown; exit 1'
  ui_ok 'a check that passed'
  ui_fail 'a check that failed' 'its remedy'
  ui_note 'a note'
} 2>&1)
says "$out" 'shown' "a step's output is printed as it is"
says "$out" 'also shown' "and so is a failed one's"
says "$out" '  ✗ a check that failed' 'a failure is still a cross'
says "$out" '    its remedy' 'with its remedy beneath it'
check 'no escape is written' 1 "$(grep -q $'\033' <<<"$out"; echo $?)"

printf '\n'
exit "$fail"
