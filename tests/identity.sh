#!/bin/bash
# Which identity does a repository resolve to, given its remote? (ADR 0011, ADR 0018)
#
# Usage: tests/identity.sh <rendered-gitconfig> <config-personal>
#
# The rendered `~/.gitconfig` is asked the question git itself asks: for a remote of this
# shape, which address commits? That is the whole point of the `includeIf` set, and it is
# the one thing in it that cannot be read off the file — a pattern that looks right and
# matches nothing is the failure this exists to catch, and it fails silently everywhere
# else, because with no default git simply refuses at a first commit far from here.
#
# It runs in the op-less branch, so the client-issued identity is absent and only the
# cleartext one is asserted. That is the same boundary CI renders at.
#
# The addresses are read out of the rendered configuration rather than named here: this
# stays a test of which file a remote selects, never a second copy of what is in them.

set -uo pipefail

gitconfig=${1:?usage: tests/identity.sh <rendered-gitconfig> <config-personal>}
personal_config=${2:?missing config-personal}

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
[ -n "$personal" ] || {
  printf 'The identity file states no address; nothing to assert against.\n'
  exit 1
}

home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/git"
cp "$gitconfig" "$home/.gitconfig"
cp "$personal_config" "$home/.config/git/config-personal"

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

printf 'Every owner on github.com, in both remote spellings\n'
# The person's own namespace, an organisation it belongs to, and one it has never heard of:
# the account is the identity on this host, whoever owns the repository (ADR 0018).
for owner in robocopklaus 21stdigital someone-else; do
  check "$(resolves_to "git@github.com:$owner/thing.git")" "$personal" "ssh, $owner"
  check "$(resolves_to "https://github.com/$owner/thing.git")" "$personal" "https, $owner"
done

printf '\nA repository no rule matches\n'
check "$(resolves_to 'git@gitlab.com:someone-else/thing.git')" '' 'resolves to no address'

# And the refusal that address-lessness is *for*. Signing is switched off for this one
# commit: op-ssh-sign is not on a CI runner, and its absence would fail the commit for a
# reason that is not the one under test.
unmatched=$(mktemp -d "$home/repo.XXXXXX")
git -C "$unmatched" init -q
git -C "$unmatched" remote add origin 'git@gitlab.com:someone-else/thing.git'
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
