#!/bin/bash
# The canonical form of ~/.claude/settings.json, against the rendered modify_ script.
#
# The script's whole job is a boundary (ADR 0006, amended): a rewrite that changes no
# value must produce no finding, and a rewrite that changes any value must still produce
# one. Both halves are asserted here, because getting either one alone is easy and useless
# — a script that always echoed its stdin would pass the first, and the script that
# existed before this one passed the second.
#
# The declaration is never spelled out in this file. It is obtained from the script
# itself, by handing it the machine copy a fresh machine has: none. A second copy of the
# declared value living in a test is the second list this repository spends its rules
# preventing, and it would be the copy that drifts.
set -uo pipefail

modify=${1:?usage: tests/claude-settings.sh <rendered modify script>}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

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
# Whether a command succeeded, as the 0/1 `check` compares.
did() {
  "$@" >/dev/null 2>&1 && echo 0 || echo 1
}

declared="$root/declared.json"
out="$root/out.json"

printf '\nA machine with no copy of the file: the declaration, unchanged\n'
printf '' | bash "$modify" >"$declared"
check 'emits valid JSON' 0 "$(did jq -e . "$declared")"
check 'ends with a newline' 0 "$([ -z "$(tail -c1 "$declared")" ] && echo 0 || echo 1)"

printf '\nA pure reorder: the target is the machine copy, byte for byte\n'
# `jq -S` sorts keys recursively, so this is the defect the script exists for and a test
# of the nested case at the same time: a script that reordered only the top level would
# leave the inner objects in the declaration's order and fail the comparison below.
reordered="$root/reordered.json"
jq -S . "$declared" >"$reordered"
bash "$modify" <"$reordered" >"$out"
check 'the machine order is reproduced exactly' 0 "$(did cmp -s "$reordered" "$out")"
check 'and no value changed' 0 "$(did cmp -s <(jq -S . "$declared") <(jq -S . "$out"))"

printf '\nA value the repository does not declare: still reported, never swallowed\n'
# The other half of the boundary, and the one ADR 0010 depends on: a foreign key is a
# decision owed to the repository, so the target must not carry it.
foreign="$root/foreign.json"
jq '. + {"modelSettings": {"claude-opus-5": {"effortLevel": "medium"}}}' "$declared" >"$foreign"
bash "$modify" <"$foreign" >"$out"
check 'the undeclared value is absent from the target' 1 "$(did jq -e 'has("modelSettings")' "$out")"
check 'so the target differs from the machine, and chezmoi reports it' 1 "$(did cmp -s "$foreign" "$out")"

printf '\nA declared value the machine has lost: restored\n'
missing="$root/missing.json"
jq 'del(.theme)' "$declared" >"$missing"
bash "$modify" <"$missing" >"$out"
check 'the declared key comes back' 0 "$(did jq -e 'has("theme")' "$out")"

printf '\nNothing readable as JSON: the same answer as nothing at all\n'
# The degrade path. It is the behaviour of every day before this script existed, which is
# what makes it the safe answer rather than a guess.
printf 'not json at all\n' | bash "$modify" >"$out"
check 'the declaration is emitted unchanged' 0 "$(did cmp -s "$declared" "$out")"

printf '\n%d passed, %d failed\n\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
