#!/bin/bash
# Exercises the rendered `drift` (§7) against stubbed inventories.
#
# Usage: tests/drift.sh <rendered-drift>
#
# What this holds is drift's own logic — which section an entry lands in, and how a
# bundle's provenance is decided — never a second list of what this machine should have.
# That list is the Brewfile: the entries bent below are *read out of it* rather than named
# here, so editing the inventory can never quietly turn a check into a no-op. The report
# itself stays the oracle for machine state (§8).
#
# The one place this does reach into its subject is the prefix cascade, which it rewrites
# out of the rendered script so the stubs are not shadowed. That couples the test to the
# literal text of `lib/homebrew.sh` — loudly, since every case fails at once if it changes.

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
  check "$?" 0 "$3"
}

silent() {
  grep -q -- "$2" <<<"$1"
  check "$?" 1 "$3"
}

# A machine, built from the repository's own declarations and then bent away from them
# one case at a time. Everything the command asks the machine is answered by a stub, so
# the run is the same on a developer's Mac and on a bare CI runner.
machine=$(mktemp -d)
trap 'rm -rf "$machine"' EXIT
mkdir -p "$machine/bin" "$machine/Applications"

sed -n 's/^tap "\([^"]*\)".*/\1/p' "$repo/Brewfile" >"$machine/taps"
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
  "tap") cat "$machine/taps" ;;
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
says "$report" '^No drift' 'says so'
silent "$report" 'Missing on the machine' 'prints no missing section'
silent "$report" 'Not in the repository' 'prints no unmanaged section'
silent "$report" 'Diverged value' 'prints no diverged section'
silent "$report" 'incomplete' 'claims no gap in its own reach'

printf '\nA machine the repository declares more than it has\n'
# The entries taken away are whichever the Brewfile declares first, so this stays a test
# of drift rather than a second copy of the inventory.
tap=$(head -1 "$machine/taps")
formula=$(head -1 "$machine/formulae")
cask=$(head -1 "$machine/casks")
app_id=$(head -1 "$machine/mas" | awk '{print $1}')
app_name=$(head -1 "$machine/mas" | cut -d' ' -f2-)
for inventory in taps formulae casks mas; do
  tail -n +2 "$machine/$inventory" >"$machine/$inventory.kept"
  mv "$machine/$inventory.kept" "$machine/$inventory"
done
cp "$machine/formulae" "$machine/leaves"
report=$(drift)
check "$?" 1 'exits 1'
says "$report" '^Missing on the machine' 'prints the missing section'
says "$report" "Tap $tap" 'names the missing tap'
says "$report" "Formula $formula" 'names the missing formula'
says "$report" "Cask $cask" 'names the missing cask'
says "$report" "App Store $app_name ($app_id)" 'names the missing App Store entry with its id'
silent "$report" 'Not in the repository' 'prints no unmanaged section'

printf '\nA machine holding more than the repository declares\n'
# A declared formula that stops being a leaf is installed as another's dependency:
# present, so neither missing nor a decision owed.
dependency=$(head -1 "$machine/formulae")
grep -vxF "$dependency" "$machine/formulae" >"$machine/leaves"
printf 'undeclared-formula\n' >>"$machine/leaves"
printf 'undeclared-cask\n' >>"$machine/casks"
printf '424242 Undeclared App\n' >>"$machine/mas"
report=$(drift)
check "$?" 1 'exits 1'
says "$report" '^Not in the repository' 'prints the unmanaged section'
says "$report" 'Formula undeclared-formula' 'names the undeclared leaf'
says "$report" 'Cask undeclared-cask' 'names the undeclared cask'
says "$report" 'App Store Undeclared App (424242)' 'names the undeclared App Store entry'
silent "$report" "Formula $dependency" 'says nothing about a declared formula that is not a leaf'

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
says "$report" 'Application Dragged In.app' 'reports a bundle from neither source'
silent "$report" 'Application From The Store.app' 'says nothing about an App Store bundle'
silent "$report" 'Application Named By A Cask.app' 'says nothing about a bundle a cask names'
silent "$report" 'Application Relocated.app' 'says nothing about a bundle a cask relocates'
silent "$report" 'Application Deleted By A Cask.app' "says nothing about a bundle a cask's uninstall names"
silent "$report" 'Application From A Package.app' "says nothing about a bundle a cask's package receipt names"
silent "$report" 'Application Preview.app' 'says nothing about an application macOS signs itself'

printf '\nManaged files\n'
printf ' M .gitconfig\nMM .zshrc\n' >"$machine/chezmoi-status"
report=$(drift)
check "$?" 1 'exits 1'
says "$report" '^Diverged value' 'prints the diverged section'
says "$report" '.gitconfig' 'names the diverged file'

printf '\nA machine that cannot answer\n'
mv "$machine/bin/mas" "$machine/bin/mas.gone"
report=$(drift)
check "$?" 1 'exits 1'
says "$report" '^This report is incomplete' 'says its reach fell short'
says "$report" 'mas CLI is not installed' 'names the question that went unanswered'
silent "$report" 'App Store .*([0-9]' 'reports no App Store entry in either direction'
mv "$machine/bin/mas.gone" "$machine/bin/mas"

# An inventory nobody could read must not read as an empty inventory: every cask would
# otherwise be missing, and every application a stranger.
printf '#!/bin/bash\nexit 1\n' >"$machine/bin/brew"
chmod +x "$machine/bin/brew"
report=$(drift)
check "$?" 1 'exits 1'
says "$report" 'brew leaves did not answer' 'names the sweep that did not run'
silent "$report" 'Application Dragged In.app' 'sweeps no application on claims it could not read'

printf '\n'
if [ "$failures" -gt 0 ]; then
  printf '%d check(s) failed.\n' "$failures"
  exit 1
fi
printf 'All checks passed.\n'
