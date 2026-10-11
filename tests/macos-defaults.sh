#!/bin/bash
# The managed defaults module, at its two-call interface, against a `defaults` stub that is
# strict about the write spelling the way the real one is.
#
# `defaults write … -bool` accepts `true`, `false`, `yes` and `no`, and rejects `1` and
# `0` with its usage text and exit 255. `defaults read` answers in `1`/`0`. The module
# needs both spellings — one to compare against, one to write — and for a long time the
# phase used the comparison spelling for the write too. That is invisible on a converged
# machine, because a value that already agrees is never written: it took a single boolean
# drifting on a live machine to surface it, and it took the whole phase down with
# `exit status 255` when it did.
#
# So the oracle here is not "the module ran". It is that a *drifted boolean* is reported
# in the read spelling and written back in the write spelling, against a stub that refuses
# the wrong one — which is the one condition the bug needed and a converged machine never
# provides. Both consumers, the System settings phase and `drift`, reach the module only
# through these two calls, so this is where the spellings are tested and nowhere else.
set -uo pipefail

lib=${1:?usage: tests/macos-defaults.sh <rendered lib/macos-defaults.sh>}
repo=$(cd "$(dirname "$0")/.." && pwd)
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
bin="$root/bin"
mkdir -p "$bin"
tab=$'\t'

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
  # what killed the phase, and the stdout is what the user saw instead of a System settings line.
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
      -int | -float | -string) printf '%s\n' "$value" >"$slot" ;;
      *) usage ;;
    esac
    printf 'WROTE %s %s %s %s %s\n' "$scope" "$domain" "$key" "$flag" "$value" >>"$STUB_STORE/.log"
    ;;
  *) usage ;;
esac
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

# One of the two calls, in a fresh shell that has sourced the module and nothing else.
module() {
  STUB_STORE=$store PATH="$bin:$PATH" bash -c 'source "$1"; shift; "$@"' _ "$lib" "$@" 2>&1
}

# What the System settings phase does with the two calls, minus its output: every diverged
# entry, written back by name.
converge() {
  local scope domain key
  while IFS="$tab" read -r scope domain key _; do
    module managed_default_apply "$scope" "$domain" "$key" || return
  done < <(module managed_defaults_diverged)
}

# The expected value `diverged` reports for one entry on the machine as it stands.
expected_for() {
  module managed_defaults_diverged |
    awk -F"$tab" -v scope="$1" -v domain="$2" -v key="$3" \
      '$1 == scope && $2 == domain && $3 == key { print $5 }'
}

# A machine that holds nothing at all: every managed key disagrees and is unset. This is
# the fresh-bootstrap case, and the one the bug would have taken down at the first boolean.
store="$root/machine"
mkdir -p "$store"
diverged=$(module managed_defaults_diverged)
check 'an unconfigured machine disagrees with every declared entry' \
  "$(grep -c '^\[\[macosDefaults\]\]' "$repo/home/.chezmoidata/macos-defaults.toml")" \
  "$(grep -c . <<<"$diverged")"
check 'every entry it disagrees with is unset' '' "$(awk -F"$tab" '$6 != ""' <<<"$diverged")"
check 'a boolean declared true is expected as 1' '1' "$(expected_for any com.apple.dock magnification)"
check 'a boolean declared false is expected as 0' '0' "$(expected_for any com.apple.dock show-recents)"
check 'the HOME token is expanded in every expected value' '' "$(grep '[$]{HOME}' <<<"$diverged")"
check 'the per-machine entry is labelled with its scope' 'NSGlobalDomain -currentHost' \
  "$(awk -F"$tab" '$1 == "currentHost" { print $4 }' <<<"$diverged")"

output=$(converge)
check 'an unconfigured machine converges' 0 "$?"
check 'no usage text is printed' '' "$(grep 'Command line interface' <<<"$output")"
check 'every boolean is written in a spelling defaults accepts' '' \
  "$(grep -E '^WROTE .* -bool (0|1)$' "$store/.log")"
check 'the per-machine entry is written under its scope' \
  'WROTE currentHost NSGlobalDomain com.apple.mouse.tapBehavior -int 1' \
  "$(grep '^WROTE currentHost ' "$store/.log")"
# `${HOME}` is expanded on the way to `defaults`, not stored as the token: a literal one
# would send screenshots to a directory of that name.
check 'the HOME token is expanded before it is written' "$HOME/Downloads" \
  "$(cat "$store/any.com.apple.screencapture.location")"

# The same machine again. Everything now agrees, so nothing is reported and nothing is
# written — the property the phase claims for a mid-workday apply.
: >"$store/.log"
check 'a converged machine disagrees with nothing' '' "$(module managed_defaults_diverged)"
converge
check 'a converged machine writes nothing' '' "$(cat "$store/.log")"

# One boolean drifted, which is the reported failure exactly: the machine was converged
# apart from `com.apple.dock show-recents`, and the phase died writing it back.
printf '1\n' >"$store/any.com.apple.dock.show-recents"
check 'a drifted boolean is the one entry reported, in the read spelling' \
  "any${tab}com.apple.dock${tab}show-recents${tab}com.apple.dock${tab}0${tab}1" \
  "$(module managed_defaults_diverged)"
converge
check 'a drifted boolean converges' 0 "$?"
check 'the drifted boolean is the only write, in the write spelling' \
  'WROTE any com.apple.dock show-recents -bool false' "$(cat "$store/.log")"
check 'the drifted boolean now agrees' '0' "$(cat "$store/any.com.apple.dock.show-recents")"

# An entry the table does not hold is refused, and nothing reaches `defaults`.
: >"$store/.log"
module managed_default_apply any com.apple.dock not-declared >/dev/null
check 'an undeclared entry is refused' 1 "$?"
check 'an undeclared entry writes nothing' '' "$(cat "$store/.log")"

exit "$fail"
