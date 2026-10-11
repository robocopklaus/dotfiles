#!/bin/bash
# The repository's check: render what chezmoi renders, lint it, and run every test against
# it. The lint tier runs this, and so does anyone about to push — one list of what "the
# check" is, rather than one in the workflow and a reconstruction at the desk.
#
# Usage: tests/check.sh
#
# What stays in the workflow is what needs more than this tree: the dry-run apply against
# a scratch destination, and the checks that ask Homebrew's live package data whether an
# inventory entry or a Dock reference resolves.
#
# Every step runs even after one fails, so a single run names every failure; the exit
# status is 1 if any did.

set -uo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo" || exit 1

# The three tools the steps reach for, asked of the machine. Each is a Brewfile entry, so
# the remedy is the inventory's, not a one-off install.
missing=()
for tool in chezmoi shellcheck jq; do
  command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
if [ ${#missing[@]} -gt 0 ]; then
  printf 'Not on PATH: %s. Re-run the bootstrap, which installs them from the Brewfile.\n' "${missing[*]}"
  exit 1
fi

out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT
mkdir -p "$out/scripts" "$out/bin" "$out/other"

failed=()
step() {
  local name=$1
  shift
  printf '\n== %s\n' "$name"
  "$@" || failed+=("$name")
}

render() {
  chezmoi execute-template --source . <"$1" >"$2"
}

# Sources are .tmpl, so everything is rendered first: a template that fails to render is
# caught a step earlier than one that renders to broken shell.
render_all() {
  local template status=0
  for template in home/.chezmoiscripts/*.tmpl; do
    render "$template" "$out/scripts/$(basename "$template" .tmpl)" || status=1
  done
  # drift is shell too, and the one piece of it a human runs by hand, so it is rendered and
  # linted with the phase scripts. It is kept out of the directory the header check reads:
  # it is a command, not a phase, so it carries no phase header.
  render home/dot_local/bin/executable_drift.tmpl "$out/bin/drift.sh" || status=1
  # Rendered for the tests alone, and kept out of the lint: the library defines functions
  # only its includers call, and the gitconfig is not shell.
  render home/.chezmoitemplates/lib/macos-defaults.sh "$out/other/macos-defaults.sh" || status=1
  render home/dot_gitconfig.tmpl "$out/other/gitconfig" || status=1
  return "$status"
}

# Presence only — the prose is never read.
script_headers() {
  local rendered field status=0
  for rendered in "$out"/scripts/*.sh; do
    for field in '# Phase:' '# Requires:'; do
      if ! grep -q "^$field" "$rendered"; then
        printf '%s: missing %s header field\n' "$(basename "$rendered")" "'$field'"
        status=1
      fi
    done
  done
  return "$status"
}

step 'Render' render_all
step 'Shellcheck' shellcheck "$out"/scripts/*.sh "$out"/bin/*.sh tests/*.sh
step 'Script headers' script_headers

# drift's own logic, against stubbed inventories. What the machine actually holds is the
# end-to-end tier's question, and the report is its oracle.
step 'drift' tests/drift.sh "$out/bin/drift.sh"

# The gate's two stops, against stubbed system commands. Only the cases that install
# nothing are covered, on purpose — see the header of tests/gate.sh.
step 'The gate' tests/gate.sh "$out/scripts/run_before_20-gate.sh"

# The managed defaults module's two spellings, against a `defaults` stub that refuses the
# wrong one the way the real binary does. A converged machine writes nothing at all, so the
# stub is also what supplies the drifted boolean the failure needed. The module is tested
# at its interface, which both the defaults phase and drift reach it through.
step 'The managed defaults' tests/macos-defaults.sh "$out/other/macos-defaults.sh"

# The Dock phase's PATH, under a shell that never loaded Homebrew — a bootstrap's. A
# routine apply inherits a login shell that already has, which is why the missing load
# surfaced only on a fresh machine.
step 'The Dock phase' tests/dock.sh "$out/scripts/run_onchange_after_61-dock.sh"

# The progress view, folded under a pseudo-terminal and unfolded without one. The runner
# has no terminal, so every phase CI runs takes the unfolded path, and without this step
# the folded one — every bootstrap at a desk — is never exercised. ADR 0017
step 'The progress view' tests/ui.sh

# Which identity a remote selects, asked of the real git against the rendered
# configuration. A pattern that looks right and matches nothing is silent everywhere else:
# with no default, it surfaces as a refused commit far from here. ADR 0011
step 'Identity selection' tests/identity.sh "$out/other/gitconfig" home/dot_config/git/config-personal

# The agent's attribution hook, fed the payloads it is for. A hook that matches nothing
# fails silently, exactly like no hook at all.
step 'The attribution hook' tests/attribution.sh home/dot_claude/settings.json

if [ ${#failed[@]} -gt 0 ]; then
  printf '\nFailed: %s\n' "${failed[*]}"
  exit 1
fi
printf '\nEvery check passed.\n'
