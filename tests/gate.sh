#!/bin/bash
# The gate's control flow, against stubbed system commands.
#
# The gate stops in two places since it began acquiring the trust chain (ADR 0012), and
# the order is the whole point: the foundation is what the acquisition stands on, so a
# machine missing it must be refused *before* anything is installed. That ordering is
# invisible in a passing bootstrap and expensive to get wrong, which is what this covers.
#
# Every case runs with `CI` set, and that is load-bearing rather than incidental. With it
# unset the gate reaches the acquisition, and the acquisition is not stubbable: the prefix
# cascade puts the real Homebrew ahead of anything this file puts on the PATH, so the
# casks are installed for real. That is not hypothetical — an earlier version of this file
# ran one case with `CI` empty and installed 1Password on the CI runner, which put `op` on
# the PATH and broke a later step that renders the work identity. A test that installs
# software to prove it can is not a test.
#
# For the same reason the checks that call `op` are not driven from here. The cascade
# puts the real `op` ahead of any stub too, so a case about the CLI integration would be
# asking what the machine running the test has configured rather than what the gate does —
# passing on a laptop with a vault, failing on a runner without one, and proving nothing
# either way. The integration check and the acquisition are both bare-metal behaviour,
# which CI already records as knowingly unverified.
#
# The app data check (ADR 0016) is the exception, and it is one because of its reason
# rather than in spite of it: it calls nothing, reading only a path under $HOME, which
# every case here already controls.
#
# What is left is the part that is genuinely the gate's own: the order it does things in,
# what it declines to do under CI, and the checks it can answer from the filesystem.
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
# The foundation refuses under CI too: only the 1Password items degrade.
out=$(HOME="$home" PATH="$bin:$PATH" STUB_NO_CLT=1 CI=1 bash "$gate" 2>&1)
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
# No settings file at all is the machine whose app has never been opened. It must fall
# through to the integration check rather than claim a permission problem.
silent "$out" "app data cannot be read" 'says nothing about app data when the file is absent'

# The app data check (ADR 0016), which is the one 1Password item this file can drive: it
# reads a path under $HOME and calls nothing. Under CI it reports rather than refuses,
# like every other 1Password item, so the case asserts the message and not the exit.
#
# chmod is the whole mechanism, and root is not subject to it — as root the file stays
# readable, the branch never fires, and the case would pass while proving nothing.
printf '\nThe app data is present but unreadable: the gate names the permission, not the toggle\n'
if [ "$(id -u)" = 0 ]; then
  printf '  skip app data case (running as root: chmod cannot make a file unreadable)\n'
else
  home="$root/home-appdata"
  settings="$home/Library/Group Containers/2BUA8C4S2C.com.1password/Library/Application Support/1Password/Data/settings"
  mkdir -p "$settings"
  : >"$settings/settings.json"
  chmod 000 "$settings/settings.json"
  out=$(HOME="$home" PATH="$bin:$PATH" CI=1 bash "$gate" 2>&1)
  code=$?
  check 'exits 0' 0 "$code"
  says "$out" "app data cannot be read" 'names the unreadable app data'
  says "$out" 'OP_BIOMETRIC_UNLOCK_ENABLED=true' 'gives the remedy that can actually be applied'
  chmod 644 "$settings/settings.json"
fi

printf '\n%d passed, %d failed\n\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
