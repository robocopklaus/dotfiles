#!/bin/bash
# Which identity does a repository resolve to, given its remote? (§6.5, ADR 0011)
#
# Usage: tests/identity.sh <rendered-gitconfig> <config-personal> <config-company>
#
# The rendered `~/.gitconfig` is asked the question git itself asks: for a remote of this
# shape, which address commits? That is the whole point of the `includeIf` set, and it is
# the one thing in it that cannot be read off the file — a pattern that looks right and
# matches nothing is the failure this exists to catch, and it fails silently everywhere
# else, because with no default git simply refuses at a first commit far from here.
#
# It runs in the op-less branch, so the client-issued identity is absent and only the two
# cleartext ones are asserted. That is the same boundary CI renders at (§8, §10).
#
# The addresses are read out of the rendered configuration rather than named here: this
# stays a test of which file a remote selects, never a second copy of what is in them.

set -uo pipefail

gitconfig=${1:?usage: tests/identity.sh <rendered-gitconfig> <config-personal> <config-company>}
personal_config=${2:?missing config-personal}
company_config=${3:?missing config-company}

failures=0

check() {
  if [ "$1" = "$2" ]; then
    printf '  ok   %s\n' "$3"
  else
    printf '  FAIL %s (expected %s, got %s)\n' "$3" "$2" "$1"
    failures=$((failures + 1))
  fi
}

address_in() {
  sed -n 's/^[[:space:]]*email[[:space:]]*=[[:space:]]*//p' "$1"
}

personal=$(address_in "$personal_config")
company=$(address_in "$company_config")
[ -n "$personal" ] && [ -n "$company" ] || {
  printf 'Neither identity file states an address; nothing to assert against.\n'
  exit 1
}

home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/git"
cp "$gitconfig" "$home/.gitconfig"
cp "$personal_config" "$home/.config/git/config-personal"
cp "$company_config" "$home/.config/git/config-company"

# The identity a repository with this remote resolves to, through the real git that will
# resolve it on the machine. `includeIf` paths are written `~/…`, so HOME is what decides
# which files they find.
resolves_to() {
  local remote=$1 repo
  repo=$(mktemp -d "$home/repo.XXXXXX")
  git -C "$repo" init -q
  git -C "$repo" remote add origin "$remote"
  HOME="$home" git -C "$repo" config --get user.email
}

printf 'The personal namespace, in both remote spellings\n'
check "$(resolves_to 'git@github.com:robocopklaus/dotfiles.git')" "$personal" 'ssh'
check "$(resolves_to 'https://github.com/robocopklaus/dotfiles.git')" "$personal" 'https'

printf '\nThe company organisations, in both remote spellings\n'
# Every organisation the rendered configuration routes to the company file, so adding one
# cannot quietly leave this asserting only the first.
while IFS= read -r org; do
  [ -n "$org" ] || continue
  check "$(resolves_to "git@github.com:$org/thing.git")" "$company" "ssh, $org"
  check "$(resolves_to "https://github.com/$org/thing.git")" "$company" "https, $org"
done < <(
  awk '/^\[includeIf "hasconfig:remote\.\*\.url:\*@github\.com:/ { line = $0; next }
       /config-company/ && line { sub(/.*github\.com:/, "", line); sub(/\/\*\*".*/, "", line); print line; line = "" }' \
    "$home/.gitconfig"
)

printf '\nA repository no rule matches\n'
check "$(resolves_to 'git@github.com:someone-else/thing.git')" '' 'resolves to no address'

# And the refusal that address-lessness is *for*. Signing is switched off for this one
# commit: op-ssh-sign is not on a CI runner, and its absence would fail the commit for a
# reason that is not the one under test.
unmatched=$(mktemp -d "$home/repo.XXXXXX")
git -C "$unmatched" init -q
git -C "$unmatched" remote add origin 'git@github.com:someone-else/thing.git'
if HOME="$home" git -C "$unmatched" -c commit.gpgSign=false \
  commit -q --allow-empty -m 'should not be possible' >/dev/null 2>&1; then
  refused='no'
else
  # git's own exit code here is 128, its fatal, rather than 1 — the assertion is that it
  # would not commit, not which number it said so with.
  refused='yes'
fi
check "$refused" 'yes' 'refuses to commit rather than inventing an address'

printf '\n'
if [ "$failures" -gt 0 ]; then
  printf '%d check(s) failed.\n' "$failures"
  exit 1
fi
printf 'All checks passed.\n'
