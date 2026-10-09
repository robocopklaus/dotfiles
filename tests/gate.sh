#!/bin/bash
# The gate's control flow, against stubbed system commands.
#
# The gate stops in three places since it began acquiring the trust chain (ADR 0012) and
# then stopped paying for it on every run (ADR 0012, amended), and the order is the whole
# point: the foundation is what the privilege question can be asked on, and the privilege
# is what the acquisition spends — so a machine missing the foundation must be refused
# before it is asked for a password, and a refused password must not fall through into the
# installs it was going to pay for. That ordering is invisible in a passing bootstrap and
# expensive to get wrong, which is what this covers.
#
# Every case runs with `CI` set, and that is load-bearing rather than incidental. With it
# unset the gate reaches the acquisition, and the acquisition is not stubbable: the prefix
# cascade puts the real Homebrew ahead of anything this file puts on the PATH, so the
# casks are installed for real. That is not hypothetical — an earlier version of this file
# ran one case with `CI` empty and installed 1Password on the CI runner, which put `op` on
# the PATH and broke a later step that renders the work identity. A test that installs
# software to prove it can is not a test.
#
# For the same reason the 1Password checks are not driven from here at all. The cascade
# puts the real `op` ahead of any stub too, so a case about the CLI integration would be
# asking what the machine running the test has configured rather than what the gate does —
# passing on a laptop with a vault, failing on a runner without one, and proving nothing
# either way. The integration check and the acquisition are both bare-metal behaviour,
# which CI already records as knowingly unverified.
#
# The app data diagnosis (ADR 0016) reads only a path under $HOME and would be drivable
# from here on its own. It is not, because it is not on its own: it is reached only once
# `op account list` has come back empty, which is the part the cascade decides. A case
# for it would pass or fail on what the machine running it has configured.
#
# What is left is the part that is genuinely the gate's own: the order it does things in,
# and what it declines to do under CI.
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
# Every call is recorded, because the question two cases below ask is whether the gate
# asked for the privilege at all — and silence is the answer they are checking for.
# `-v` here and the keepalive's `-n true` are both the privilege being reached for.
echo "$*" >>"$SUDO_LOG"
[ -n "${STUB_NO_SUDO:-}" ] && exit 1
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
# `brew bundle check` is how the gate decides whether this run installs anything, and
# therefore whether it needs the privilege at all (ADR 0012, amended). The inventory
# arrives on stdin and is deliberately not read: what a case needs to choose is the
# answer, not the reasoning. The wording of the pending line is Homebrew's own, because
# the gate parses it to name what it is refusing over.
if [ "${1:-}" = "bundle" ]; then
  cat >/dev/null
  if [ -n "${STUB_PENDING:-}" ]; then
    printf '→ Cask example needs to be installed or updated.
'
    exit 1
  fi
  exit 0
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
# unless the case creates one, and its own sudo log, so one case's silence is never
# another case's leftovers.
export SUDO_LOG="$root/sudo.log"
: >"$SUDO_LOG"
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
# The privilege question sits behind this stop on purpose: asking for a password and then
# refusing the machine anyway is the one order that wastes the person's time.
silent "$out" 'may ask for your password' 'asks for no password before refusing'
check 'never reaches for the privilege' '' "$(cat "$SUDO_LOG")"

printf '\nUnder CI: the casks are skipped and 1Password reports rather than refuses\n'
home="$root/home-ci"
mkdir -p "$home"
out=$(HOME="$home" PATH="$bin:$PATH" CI=1 bash "$gate" 2>&1)
code=$?
check 'exits 0' 0 "$code"
says "$out" 'reported, not refused' 'reports the 1Password items'
silent "$out" 'Preflight gate: installing' 'installs no cask'
silent "$out" 'precondition(s) not met' 'refuses nothing'

printf '\nNothing to install: the everyday update asks for no password\n'
home="$root/home-nothing-pending"
mkdir -p "$home"
: >"$SUDO_LOG"
out=$(HOME="$home" PATH="$bin:$PATH" CI=1 bash "$gate" 2>&1)
code=$?
check 'exits 0' 0 "$code"
silent "$out" 'may ask for your password' 'announces no password prompt'
# The whole point of the change: an update that installs nothing never reaches for root,
# so it runs in a context with nobody sitting at the terminal.
check 'reaches for no privilege at all' '' "$(cat "$SUDO_LOG")"
silent "$out" 'Installing Homebrew' 'acquires no Homebrew'
silent "$out" 'Preflight gate: installing' 'installs no cask'

printf '\nSomething to install: the gate acquires the privilege as it always did\n'
home="$root/home-pending"
mkdir -p "$home"
: >"$SUDO_LOG"
out=$(HOME="$home" PATH="$bin:$PATH" CI=1 STUB_PENDING=1 bash "$gate" 2>&1)
code=$?
check 'exits 0' 0 "$code"
says "$out" 'may ask for your password' 'announces the password prompt'
check 'reaches for the privilege' 0 "$(grep -q -- '-v' "$SUDO_LOG" && echo 0 || echo 1)"

printf '\nSomething to install and no terminal: it refuses, naming the installs\n'
home="$root/home-pending-no-tty"
mkdir -p "$home"
: >"$SUDO_LOG"
# Stdin is not a terminal here, which is the condition the gate reads. The privilege is
# refused as it would be with nobody to ask.
out=$(HOME="$home" PATH="$bin:$PATH" CI=1 STUB_PENDING=1 STUB_NO_SUDO=1 bash "$gate" </dev/null 2>&1)
code=$?
check 'exits 1' 1 "$code"
says "$out" 'no terminal to ask for the administrator password' 'names the missing terminal, not a failed precondition'
says "$out" 'Pending: Cask example' 'names what it is refusing over'
says "$out" 'Run the command again in a terminal window' 'states one remedy'
# A refused privilege must not fall through into the acquisition it was going to pay for.
silent "$out" 'Installing Homebrew' 'acquires no Homebrew'
silent "$out" 'Preflight gate: installing' 'installs no cask'
silent "$out" 'SSH agent socket' 'never reaches the trust-chain checks'

printf '\n%d passed, %d failed\n\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
