#!/bin/bash
# Exercises the rendered `drift` (§7) against stubbed inventories.
#
# Usage: tests/drift.sh <rendered-drift>
#
# What this holds is drift's own logic — which section an entry lands in, and how a
# bundle's provenance is decided — never a second list of what this machine should have.
# That list is the Brewfile, and the declarations below are read out of it, so the two
# cannot disagree. The report itself is the oracle for machine state (§8).

set -uo pipefail

rendered=${1:?usage: tests/drift.sh <rendered-drift>}
repo=$(cd "$(dirname "$0")/.." && pwd)

failures=0

check() {
  if [ "$1" = "$2" ]; then
    printf '  ok   %s\n' "$3"
  else
    printf '  FAIL %s (expected %s, got %s)\n' "$3" "$2" "$1"
    failures=$((failures + 1))
  fi
}

says() {
  grep -q -- "$2" <<<"$1"
  check "$?" "$3" "$4"
}

# A machine, built from the repository's own declarations and then bent away from them
# one case at a time. Everything the command asks the machine is answered by a stub, so
# the run is the same on a developer's Mac and on a bare CI runner.
machine=$(mktemp -d)
trap 'rm -rf "$machine"' EXIT
mkdir -p "$machine/bin" "$machine/Applications"

sed -n 's/^brew "\([^"]*\)".*/\1/p' "$repo/Brewfile" >"$machine/formulae"
sed -n 's/^cask "\([^"]*\)".*/\1/p' "$repo/Brewfile" >"$machine/casks"
sed -n 's/^mas "\([^"]*\)", id: \([0-9][0-9]*\).*/\2 \1/p' "$repo/Brewfile" >"$machine/mas"
cp "$machine/formulae" "$machine/leaves"
printf '{"casks":[]}\n' >"$machine/cask-info.json"
: >"$machine/chezmoi-status"
: >"$machine/receipt-files"

cat >"$machine/bin/brew" <<EOF
#!/bin/bash
case "\$*" in
  "list --formula -1") cat "$machine/formulae" ;;
  "list --cask -1") cat "$machine/casks" ;;
  "leaves") cat "$machine/leaves" ;;
  *) cat "$machine/cask-info.json" ;;
esac
EOF

# \`id  Name  (version)\`, the shape drift parses.
cat >"$machine/bin/mas" <<EOF
#!/bin/bash
awk '{ id = \$1; \$1 = ""; sub(/^ /, "", \$0); printf "%s  %s  (1.0)\n", id, \$0 }' "$machine/mas"
EOF

cat >"$machine/bin/chezmoi" <<EOF
#!/bin/bash
cat "$machine/chezmoi-status"
EOF

cat >"$machine/bin/pkgutil" <<EOF
#!/bin/bash
cat "$machine/receipt-files"
EOF

# Apple signs its own applications with an authority no Developer ID application carries.
cat >"$machine/bin/codesign" <<'EOF'
#!/bin/bash
case "$*" in
  *Preview.app) printf 'Authority=macOS Software Signing\n' ;;
  *) printf 'Authority=Developer ID Application: Someone (ABCDE12345)\n' ;;
esac
EOF

chmod +x "$machine/bin"/*

# The prefix cascade prepends Homebrew's own bin to PATH, which on a real Mac would shadow
# the stubs; pointed at a path that does not exist it is the no-op it is before Homebrew.
sed -e "s|/Applications/\*\.app|$machine/Applications/*.app|" \
  -e "s|/opt/homebrew/bin/brew|$machine/absent/brew|" \
  -e "s|/usr/local/bin/brew|$machine/absent/brew|" \
  "$rendered" >"$machine/drift"

drift() {
  PATH="$machine/bin:/usr/bin:/bin:/usr/sbin:/sbin" bash "$machine/drift" 2>&1
}

printf 'A converged machine\n'
report=$(drift)
check "$?" 0 'exits 0'
says "$report" '^No drift' 0 'says so'
says "$report" 'Missing on the machine' 1 'prints no missing section'
says "$report" 'Not in the repository' 1 'prints no unmanaged section'
says "$report" 'Diverged value' 1 'prints no diverged section'

printf '\nA machine the repository declares more than it has\n'
grep -v '^chezmoi$' "$machine/formulae" >"$machine/formulae.kept"
mv "$machine/formulae.kept" "$machine/formulae"
grep -v '^ghostty$' "$machine/casks" >"$machine/casks.kept"
mv "$machine/casks.kept" "$machine/casks"
grep -v '^361309726 ' "$machine/mas" >"$machine/mas.kept"
mv "$machine/mas.kept" "$machine/mas"
report=$(drift)
check "$?" 1 'exits 1'
says "$report" '^Missing on the machine' 0 'prints the missing section'
says "$report" 'Formula chezmoi' 0 'names the missing formula'
says "$report" 'Cask ghostty' 0 'names the missing cask'
says "$report" 'App Store Pages (361309726)' 0 'names the missing App Store entry with its id'
says "$report" 'Not in the repository' 1 'prints no unmanaged section'

printf '\nA machine holding more than the repository declares\n'
# `git` stays installed but stops being a leaf: a declared formula pulled in as another's
# dependency is present, so it is neither missing nor a decision owed.
grep -v '^git$' "$machine/formulae" >"$machine/leaves"
printf 'undeclared-formula\n' >>"$machine/leaves"
printf 'undeclared-cask\n' >>"$machine/casks"
printf '424242 Undeclared App\n' >>"$machine/mas"
report=$(drift)
check "$?" 1 'exits 1'
says "$report" '^Not in the repository' 0 'prints the unmanaged section'
says "$report" 'Formula undeclared-formula' 0 'names the undeclared leaf'
says "$report" 'Cask undeclared-cask' 0 'names the undeclared cask'
says "$report" 'App Store Undeclared App (424242)' 0 'names the undeclared App Store entry'
says "$report" 'Formula git' 1 'says nothing about a declared formula that is not a leaf'

printf '\nApplications, by where each bundle came from\n'
mkdir -p "$machine/Applications/Dragged In.app/Contents"
mkdir -p "$machine/Applications/From The Store.app/Contents/_MASReceipt"
: >"$machine/Applications/From The Store.app/Contents/_MASReceipt/receipt"
mkdir -p "$machine/Applications/Named By A Cask.app/Contents"
mkdir -p "$machine/Applications/Relocated.app/Contents"
mkdir -p "$machine/Applications/Deleted By A Cask.app/Contents"
mkdir -p "$machine/Applications/From A Package.app/Contents"
mkdir -p "$machine/Applications/Preview.app/Contents"
cat >"$machine/cask-info.json" <<'JSON'
{"casks": [{"artifacts": [
  {"app": ["Named By A Cask.app"]},
  {"app": ["Original.app", {"target": "Relocated.app"}]},
  {"uninstall": [{"delete": ["/Applications/Deleted By A Cask.app"], "pkgutil": ["com.example.package"]}]}
]}]}
JSON
printf 'From A Package.app\nFrom A Package.app/Contents\n' >"$machine/receipt-files"
report=$(drift)
check "$?" 1 'exits 1'
says "$report" 'Application Dragged In.app' 0 'reports a bundle from neither source'
says "$report" 'Application From The Store.app' 1 'says nothing about an App Store bundle'
says "$report" 'Application Named By A Cask.app' 1 'says nothing about a bundle a cask names'
says "$report" 'Application Relocated.app' 1 'says nothing about a bundle a cask relocates'
says "$report" 'Application Deleted By A Cask.app' 1 "says nothing about a bundle a cask's uninstall names"
says "$report" 'Application From A Package.app' 1 "says nothing about a bundle a cask's package receipt names"
says "$report" 'Application Preview.app' 1 'says nothing about an application macOS signs itself'

printf '\nManaged files\n'
printf ' M .gitconfig\nMM .zshrc\n' >"$machine/chezmoi-status"
report=$(drift)
check "$?" 1 'exits 1'
says "$report" '^Diverged value' 0 'prints the diverged section'
says "$report" '.gitconfig' 0 'names the diverged file'

printf '\n'
if [ "$failures" -gt 0 ]; then
  printf '%d check(s) failed.\n' "$failures"
  exit 1
fi
printf 'All checks passed.\n'
