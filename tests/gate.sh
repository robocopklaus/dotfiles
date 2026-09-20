#!/bin/bash
# The gate's control flow, against stubbed system commands.
#
# The gate stops in two places since it began acquiring the trust chain (ADR 0012), and
# the order is the whole point: the foundation is what the acquisition stands on, so a
# machine missing it must be refused *before* anything is installed. That ordering is
# invisible in a passing bootstrap and expensive to get wrong, which is what this covers.
#
# Deliberately narrow. Only the two cases that install nothing are here: forcing the
# acquisition path would mean running `brew install --cask 1password` for real on any
# machine that lacks it, and a test that installs software to prove it can is not a test.
# The acquisition itself is reachable only on bare metal, which §8 already records as
# knowingly unverified.
set -uo pipefail

gate=${1:?usage: tests/gate.sh <rendered gate>}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
bin="$root/bin"
mkdir -p "$bin"

# Everything the gate shells out to for the foundation, answering yes — except
# xcode-select, which answers to $STUB_NO_CLT so one case can fail the foundation.
cat >"$bin/sudo" <<'EOF'
#!/bin/bash
exit 0
EOF
cat >"$bin/sw_vers" <<'EOF'
#!/bin/bash
echo 26.0
EOF
cat >"$bin/uname" <<'EOF'
#!/bin/bash
echo arm64
EOF
cat >"$bin/curl" <<'EOF'
#!/bin/bash
exit 0
EOF
cat >"$bin/xcode-select" <<'EOF'
#!/bin/bash
[ -n "${STUB_NO_CLT:-}" ] && exit 1
echo /Library/Developer/CommandLineTools
EOF
# A brew that refuses to do anything. It is the backstop for the promise above: if the
# gate ever reaches an install in these cases, the run fails here rather than on the
# machine. It is only consulted when no real Homebrew is on the box, since the prefix
# cascade puts a real one ahead of it — which is why neither case below relies on it.
cat >"$bin/brew" <<'EOF'
#!/bin/bash
if [ "${1:-}" = "install" ]; then
  echo "tests/gate.sh: the gate attempted an install in a case that must not install" >&2
  exit 1
fi
exit 0
EOF
chmod +x "$bin"/*

pass=0
fail=0
check() { # name expected actual
  if [ "$2" = "$3" ]; then
    printf '  ok   %s\n' "$1"
    pass=$((pass + 1))
  else
    printf '  FAIL %s (expected %s, got %s)\n' "$1" "$2" "$3"
    fail=$((fail + 1))
  fi
}
says() { # haystack pattern name
  check "$3" 0 "$(grep -q "$2" <<<"$1" && echo 0 || echo 1)"
}
silent() { # haystack pattern name
  check "$3" 1 "$(grep -q "$2" <<<"$1" && echo 0 || echo 1)"
}

# Each case runs the gate against its own empty HOME, so the agent socket is absent
# unless the case creates one.
printf '\nThe foundation fails: the gate refuses before it acquires anything\n'
home="$root/home-foundation"
mkdir -p "$home"
out=$(HOME="$home" PATH="$bin:$PATH" STUB_NO_CLT=1 CI='' bash "$gate" 2>&1)
code=$?
check 'exits 1' 1 "$code"
says "$out" 'Command Line Tools' 'names the missing foundation item'
silent "$out" 'Installing Homebrew' 'installs no Homebrew'
silent "$out" 'Preflight gate: installing' 'installs no cask'
# The second stop is never reached, so nothing it would have said may appear.
silent "$out" 'SSH agent socket' 'never reaches the trust-chain checks'

printf '\nUnder CI: the casks are skipped and 1Password reports rather than refuses\n'
home="$root/home-ci"
mkdir -p "$home"
out=$(HOME="$home" PATH="$bin:$PATH" CI=1 bash "$gate" 2>&1)
code=$?
check 'exits 0' 0 "$code"
says "$out" 'reported, not refused' 'reports the 1Password items'
silent "$out" 'Preflight gate: installing' 'installs no cask'
silent "$out" 'precondition(s) not met' 'refuses nothing'

printf '\n%d passed, %d failed\n\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
