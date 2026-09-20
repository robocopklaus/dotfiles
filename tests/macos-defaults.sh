#!/bin/bash
# The P6 defaults phase's write spelling, against a `defaults` stub that is strict about
# it the way the real one is.
#
# `defaults write … -bool` accepts `true`, `false`, `yes` and `no`, and rejects `1` and
# `0` with its usage text and exit 255. `defaults read` answers in `1`/`0`. The phase
# needs both spellings — one to compare against, one to write — and for a long time it
# used the comparison spelling for the write too. That is invisible on a converged
# machine, because a value that already agrees is never written: it took a single boolean
# drifting on a live machine to surface it, and it took the whole phase down with
# `exit status 255` when it did.
#
# So the oracle here is not "the script ran". It is that the phase converges a *drifted
# boolean* against a stub that refuses the wrong spelling — which is the one condition
# the bug needed and a converged machine never provides.
set -uo pipefail

script=${1:?usage: tests/macos-defaults.sh <rendered 60-macos-defaults.sh>}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
bin="$root/bin"
mkdir -p "$bin"

# The stub stores the machine's state as one file per scope/domain/key under $STUB_STORE,
# so `read` answers what a previous `write` was given rather than a fixture. Booleans are
# stored the way the real `defaults` answers them, in `1`/`0`, which is what makes the
# round trip — write `false`, read `0` — the thing under test.
cat >"$bin/defaults" <<'EOF'
#!/bin/bash
scope=any
if [ "${1:-}" = '-currentHost' ]; then
  scope=currentHost
  shift
fi
verb=${1:-}
shift || true

usage() {
  # The real one prints its usage to stdout and exits 255. Both matter: the exit status is
  # what killed the phase, and the stdout is what the user saw instead of a P6 line.
  echo "Command line interface to a user's defaults."
  echo '  -bool[ean] (true | false | yes | no)'
  exit 255
}

slot="$STUB_STORE/$scope.$1.$2"
case $verb in
  read)
    [ -f "$slot" ] || exit 1
    cat "$slot"
    ;;
  write)
    domain=$1 key=$2 flag=$3 value=$4
    case $flag in
      -bool)
        case $value in
          true | yes) printf '1\n' >"$slot" ;;
          false | no) printf '0\n' >"$slot" ;;
          *) usage ;;
        esac
        ;;
      -int | -string) printf '%s\n' "$value" >"$slot" ;;
      *) usage ;;
    esac
    printf 'WROTE %s %s %s %s %s\n' "$scope" "$domain" "$key" "$flag" "$value" >>"$STUB_STORE/.log"
    ;;
  *) usage ;;
esac
EOF
# The phase restarts Finder when its domain changes, which is real on the machine running
# this and has nothing to do with the write spelling.
cat >"$bin/killall" <<'EOF'
#!/bin/bash
exit 0
EOF
chmod +x "$bin"/*

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

run() {
  STUB_STORE=$store PATH="$bin:$PATH" TMPDIR=$store bash "$script" 2>&1
}

# A machine that holds nothing at all: every managed key disagrees, so every one of them
# is written — booleans, integers and strings together. This is the fresh-bootstrap case,
# and the one the bug would have taken down at the first boolean.
store="$root/machine"
mkdir -p "$store"
output=$(run)
status=$?
check 'an unconfigured machine converges' 0 "$status"
check 'no usage text is printed' '' "$(grep 'Command line interface' <<<"$output")"
check 'every boolean is written in a spelling defaults accepts' '' \
  "$(grep -E '^WROTE .* -bool (0|1)$' "$store/.log")"

# The same machine again. Everything now agrees, so nothing is written and nothing is
# restarted — the property the phase claims for a mid-workday apply.
: >"$store/.log"
run >/dev/null
check 'a converged machine converges' 0 $?
check 'a converged machine writes nothing' '' "$(cat "$store/.log")"

# One boolean drifted, which is the reported failure exactly: the machine was converged
# apart from `com.apple.dock show-recents`, and the phase died writing it back.
printf '1\n' >"$store/any.com.apple.dock.show-recents"
: >"$store/.log"
run >/dev/null
check 'a drifted boolean converges' 0 $?
check 'the drifted boolean is the only write' 'WROTE any com.apple.dock show-recents -bool false' \
  "$(cat "$store/.log")"
check 'the drifted boolean now agrees' '0' "$(cat "$store/any.com.apple.dock.show-recents")"

# `${HOME}` is expanded on the way to `defaults`, not stored as the token: a literal one
# would send screenshots to a directory of that name.
check 'the HOME token is expanded before it is written' "$HOME/Downloads" \
  "$(cat "$store/any.com.apple.screencapture.location")"

exit "$fail"
