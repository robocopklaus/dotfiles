#!/bin/bash
# Does the agent's attribution hook refuse what `attribution` turns off, and nothing else?
#
# Usage: tests/attribution.sh <claude settings.json>
#
# `attribution` set to empty strings stops Claude Code adding its trailer and footer, but
# it does not stop the agent writing them itself — which it did, on a commit already pushed
# to an open pull request. The hook beside the setting refuses any Bash command carrying
# either one. A hook that matches nothing fails silently, exactly like no hook at all, so
# it is fed the payloads it is for.
#
# The command is read out of the managed settings file rather than copied here, so this
# stays a test of the declaration and never a second copy of its pattern.

set -uo pipefail

settings=${1:?usage: tests/attribution.sh <claude settings.json>}

failures=0

check() {
  if [ "$1" = "$2" ]; then
    printf '  ok   %s\n' "$3"
  else
    printf '  FAIL %s (expected %s, got %s)\n' "$3" "$2" "$1"
    failures=$((failures + 1))
  fi
}

hook=$(jq -er '.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[0].command' "$settings") || {
  printf 'The settings file declares no PreToolUse hook on Bash.\n'
  exit 1
}

# The exit status the hook gives one Bash command, wrapped the way Claude Code hands it over.
verdict() {
  jq -cn --arg command "$1" '{tool_name: "Bash", tool_input: {command: $command}}' |
    bash -c "$hook" 2>/dev/null
  printf '%s\n' "$?"
}

printf 'The attribution hook\n'
check "$(verdict 'ls')" 0 'lets an unrelated command through'
check "$(verdict 'git commit -m "fix: a thing"')" 0 'lets a clean commit through'
check "$(verdict $'git commit -m "fix: a thing\n\nCo-Authored-By: Claude <noreply@anthropic.com>"')" 2 \
  'refuses a commit carrying the Claude trailer'
check "$(verdict $'gh pr create --body "x\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)"')" 2 \
  'refuses a pull request carrying the Claude Code footer'
check "$(verdict $'git commit -m "fix: a thing\n\nCo-Authored-By: A Person <a@example.org>"')" 0 \
  'lets a human co-author through'

if [ "$failures" -gt 0 ]; then
  printf '\n%s check(s) failed.\n' "$failures"
  exit 1
fi
printf '\nAll checks passed.\n'
