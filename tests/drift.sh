#!/bin/bash
# Exercises the rendered `drift` against stubbed inventories.
#
# Usage: tests/drift.sh <rendered-drift>
#
# What this holds is drift's own logic — which section an entry lands in, and how a
# bundle's provenance is decided — never a second list of what this machine should have.
# That list is the Brewfile: the entries bent below are *read out of it* rather than named
# here, so editing the inventory can never quietly turn a check into a no-op. The report
# itself stays the oracle for machine state.
#
# The one place this does reach into its subject is what the rendered script names in the
# filesystem: the prefix cascade, which would shadow the stubs, and the two roots a Dock
# entry is looked for under. Both are rewritten out of it. That couples the test to the
# literal text of `lib/homebrew.sh` and `lib/dock.sh` — loudly, since every case fails at
# once if either changes.

set -uo pipefail

rendered=${1:?usage: tests/drift.sh <rendered-drift>}
repo=$(cd "$(dirname "$0")/.." && pwd)

failures=0

# The separator every declaration this file reads back is written with.
tab=$'\t'

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
#
# The path is resolved once, here, because the Dock stores the bundle paths it is given
# with every symlink followed and the comparison below is made against those.
machine=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$machine"' EXIT
# The applications the Dock declaration points at live apart from the ones /Applications
# is swept for: they are declared elsewhere in the inventory, and a bundle standing in for
# one of them is not a stranger this report should name.
mkdir -p "$machine/bin" "$machine/Applications" "$machine/DockApps"

sed -n 's/^tap "\([^"]*\)".*/\1/p' "$repo/Brewfile" >"$machine/taps"
sed -n 's/^brew "\([^"]*\)".*/\1/p' "$repo/Brewfile" >"$machine/formulae"
sed -n 's/^cask "\([^"]*\)".*/\1/p' "$repo/Brewfile" >"$machine/casks"
sed -n 's/^mas "\([^"]*\)", id: \([0-9][0-9]*\).*/\2 \1/p' "$repo/Brewfile" >"$machine/mas"
cp "$machine/formulae" "$machine/leaves"
printf '{"casks":[]}\n' >"$machine/cask-info.json"
: >"$machine/chezmoi-status"
: >"$machine/receipt-files"
: >"$machine/defaults"

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

# A machine's managed defaults, keyed by the scope and key drift names them with. A key
# with no line here is one the machine was never given, which real \`defaults\` reports by
# exiting non-zero rather than by answering emptily.
cat >"$machine/bin/defaults" <<EOF
#!/bin/bash
# The Dock's own preferences, which drift exports whole rather than reading key by key.
if [ "\$1" = 'export' ]; then
  cat "$machine/dock.plist" >"\$3"
  exit
fi
if [ "\$1" = '-currentHost' ]; then
  scope="\$3 -currentHost"
  key=\$4
else
  scope=\$2
  key=\$3
fi
awk -F'\t' -v scope="\$scope" -v key="\$key" \\
  '\$1 == scope && \$2 == key { print \$3; found = 1 } END { exit !found }' "$machine/defaults"
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
  -e "s|^/Applications\$|$machine/DockApps|" \
  -e "s|^/System/Applications\$|$machine/DockSystemApps|" \
  -e "s|/opt/homebrew/bin/brew|$machine/absent/brew|" \
  -e "s|/usr/local/bin/brew|$machine/absent/brew|" \
  "$rendered" >"$machine/drift"

drift() {
  PATH="$machine/bin:/usr/bin:/bin:/usr/sbin:/sbin" bash "$machine/drift" 2>&1
}

# The Dock. Its declaration is read out of the rendered command, like every other
# inventory here, and the machine is then built from a *second* model of what that
# declaration means — which is the point: if the command stopped dropping an uninstalled
# application, or stopped generating a spacer, the two models would disagree and say so.
inlined() {
  sed -n "/<<'$1'/,/^$1\$/p" "$machine/drift" | sed '1d;$d'
}

dock_declaration=$(inlined DOCK_DECLARED)
dock_folder_declaration=$(inlined DOCK_FOLDERS)
dock_option_codes=$(inlined DOCK_OPTION_CODES)

# Every declared application, installed. What the cases below take away is what proves the
# comparison is made against the declaration *rendered*.
while IFS="$tab" read -r _ dock_app; do
  [ -n "$dock_app" ] || continue
  mkdir -p "$machine/DockApps/$dock_app.app"
done <<<"$dock_declaration"

dock_resolved() {
  realpath "$1" 2>/dev/null || printf '%s\n' "$1"
}

# The tile sequence this machine ought to hold: the declared applications that are
# installed, a spacer after each category that still has one, then the two folders.
dock_expected_tiles() {
  local category name previous='' path view sort display
  while IFS="$tab" read -r category name; do
    [ -n "$name" ] || continue
    [ -d "$machine/DockApps/$name.app" ] || continue
    if [ -n "$previous" ] && [ "$category" != "$previous" ]; then
      printf 'spacer\n'
    fi
    previous=$category
    printf 'app%s%s/DockApps/%s.app\n' "$tab" "$machine" "$name"
  done <<<"$dock_declaration"
  [ -z "$previous" ] || printf 'spacer\n'
  while IFS="$tab" read -r path view sort display; do
    [ -n "$path" ] || continue
    path=${path//\$\{HOME\}/$HOME}
    printf 'folder%s%s%s%s%s%s%s%s\n' \
      "$tab" "$(dock_resolved "$path")" "$tab" "$view" "$tab" "$sort" "$tab" "$display"
  done <<<"$dock_folder_declaration"
}

# A `com.apple.dock` plist holding exactly the tiles given, in the canonical spelling
# above. The real Dock carries a bookmark blob per tile — the reason the command walks the
# plist with `plutil` rather than converting it to JSON — and nothing reads it, so the
# fixture carries none.
dock_code() {
  awk -F"$tab" -v option="$1" -v word="$2" '$1 == option && $2 == word { print $3 }' \
    <<<"$dock_option_codes"
}

dock_plist() {
  local tiles=$1 kind path view sort display
  {
    printf '<?xml version="1.0" encoding="UTF-8"?>\n'
    printf '<plist version="1.0"><dict><key>persistent-apps</key><array>\n'
    while IFS="$tab" read -r kind path view sort display; do
      case $kind in
        app)
          printf '<dict><key>tile-type</key><string>file-tile</string><key>tile-data</key>'
          printf '<dict><key>file-data</key><dict><key>_CFURLString</key>'
          printf '<string>file://%s/</string></dict></dict></dict>\n' "$path"
          ;;
        spacer)
          printf '<dict><key>tile-type</key><string>small-spacer-tile</string>'
          printf '<key>tile-data</key><dict/></dict>\n'
          ;;
      esac
    done <<<"$tiles"
    printf '</array><key>persistent-others</key><array>\n'
    while IFS="$tab" read -r kind path view sort display; do
      [ "$kind" = 'folder' ] || continue
      printf '<dict><key>tile-type</key><string>directory-tile</string><key>tile-data</key>'
      printf '<dict><key>file-data</key><dict><key>_CFURLString</key>'
      printf '<string>file://%s/</string></dict>' "$path"
      printf '<key>showas</key><integer>%s</integer>' "$(dock_code view "$view")"
      printf '<key>arrangement</key><integer>%s</integer>' "$(dock_code sort "$sort")"
      printf '<key>displayas</key><integer>%s</integer></dict></dict>\n' \
        "$(dock_code display "$display")"
    done <<<"$tiles"
    printf '</array></dict></plist>\n'
  } >"$machine/dock.plist"
}

dock_plist "$(dock_expected_tiles)"

# The machine's defaults are taken from drift's own first report rather than parsed out
# of the declaration a second time. Against an empty stub every declared key is unset, so
# the report names each one with the value it expected; feeding those back is a converged
# machine, by the same route the Brewfile stubs take. The alternative — reading the TOML
# here — would re-implement how a declared value becomes the string `defaults` answers
# with, and two implementations of that is the one thing a drift detector must not have.
printf 'The managed defaults, on a machine that holds none of them\n'
drift |
  sed -n "s/^  Default \\(.*\\) \\([^ ]*\\): expected \\(.*\\), is unset\$/\\1${tab}\\2${tab}\\3/p" \
    >"$machine/defaults"
check "$(wc -l <"$machine/defaults" | tr -d ' ')" \
  "$(grep -c '^\[\[macosDefaults\]\]' "$repo/home/.chezmoidata/macos-defaults.toml")" \
  'reads every declared default and no other'

# The fixture above cannot falsify the code that produced it: invert the boolean branch
# and every assertion in this file still passes, while the P6 script writes the opposite
# of the declaration onto a real Mac. These three anchor the derivation to something
# outside it. The entries are still read out of the rendered declaration rather than named
# here, so they stay assertions about how a declared value becomes a string `defaults`
# answers with, and never become a second copy of the table.
declared_bool() {
  awk -F"$tab" -v want="$1" '$3 == "bool" && $4 == want && $5 == "any" { print; exit }' "$machine/drift"
}
expected_for() {
  awk -F"$tab" -v domain="$1" -v key="$2" '$1 == domain && $2 == key { print $3 }' "$machine/defaults"
}
row=$(declared_bool true)
check "$(expected_for "$(cut -f1 <<<"$row")" "$(cut -f2 <<<"$row")")" 1 \
  'expects 1 where the declaration says a boolean is true'
row=$(declared_bool false)
check "$(expected_for "$(cut -f1 <<<"$row")" "$(cut -f2 <<<"$row")")" 0 \
  'expects 0 where the declaration says a boolean is false'
# The token is spelled as a character class so the linter reads it as the literal it is.
check "$(grep -c '[$]{HOME}' "$machine/defaults")" 0 'expands the path token in every value'

cp "$machine/defaults" "$machine/defaults.declared"

printf '\nA converged machine\n'
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

printf '\nManaged defaults\n'
: >"$machine/chezmoi-status"
# The key bent is whichever the declaration carries first, read back out of the report
# rather than named here — editing the declaration cannot quietly turn this into a no-op.
scope=$(head -1 "$machine/defaults.declared" | cut -f1)
key=$(head -1 "$machine/defaults.declared" | cut -f2)
expected=$(head -1 "$machine/defaults.declared" | cut -f3)
awk -F"$tab" -v OFS="$tab" 'NR == 1 { $3 = "bent" } { print }' \
  "$machine/defaults.declared" >"$machine/defaults"
report=$(drift)
check "$?" 1 'exits 1'
says "$report" '^Diverged value' 'prints the diverged section'
says "$report" "Default $scope $key: expected $expected, is bent" 'names the key, what it expected and what it found'

# A system setting the machine does not have is a wrong setting, not an absence: macOS
# always supplies its own value, so an unset key is diverged rather than missing.
tail -n +2 "$machine/defaults.declared" >"$machine/defaults"
report=$(drift)
check "$?" 1 'exits 1'
says "$report" "Default $scope $key: expected $expected, is unset" 'reports an unset key as diverged'
missing_section=$(awk '/^Missing on the machine/ { held = 1; next } /^[^ ]/ { held = 0 } held' <<<"$report")
silent "$missing_section" 'Default' 'does not report an unset key as missing'

# The one entry carrying a host scope is declared under a domain and key another entry
# also declares, so only the scope tells the two apart in the report.
scoped_scope=$(grep -- "-currentHost$tab" "$machine/defaults.declared" | head -1 | cut -f1)
scoped_key=$(grep -- "-currentHost$tab" "$machine/defaults.declared" | head -1 | cut -f2)
grep -v -- "-currentHost$tab" "$machine/defaults.declared" >"$machine/defaults"
report=$(drift)
check "$?" 1 'exits 1'
says "$report" "Default $scoped_scope $scoped_key" 'names the scoped entry by its scope'
silent "$report" "Default ${scoped_scope% -currentHost} $scoped_key" 'says nothing about the unscoped entry of the same key'

cp "$machine/defaults.declared" "$machine/defaults"

printf '\nThe Dock\n'
# The sections above have already bent the inventories, so the report is not clean here
# and only the Dock's own line is asked about.
report=$(drift)
silent "$report" 'Dock layout' 'says nothing about a Dock that matches the declaration'

# One line, whatever moved: the layout matches or it does not, and the two sequences say
# the rest. A per-tile enumeration was rejected — it scatters one fact over many lines.
dock_plist "$(dock_expected_tiles | tail -r)"
report=$(drift)
check "$?" 1 'exits 1'
says "$report" '^Diverged value' 'prints the diverged section'
check "$(grep -c 'Dock layout' <<<"$report")" 1 'reports a rearranged Dock as one line'
says "$report" '    expected: ' 'prints the expected sequence'
says "$report" '    actual:   ' 'prints the actual sequence'
missing_section=$(awk '/^Missing on the machine/ { held = 1; next } /^[^ ]/ { held = 0 } held' <<<"$report")
silent "$missing_section" 'Dock' 'reports the Dock nowhere but under Diverged value'

# An application that never installed is the Brewfile sweep's to report, and the layout is
# compared against the declaration minus it — so a Dock short that tile reads clean here.
crowded=$(awk -F"$tab" '{ seen[$1]++ } END { for (c in seen) if (seen[c] > 1) { print c; exit } }' \
  <<<"$dock_declaration")
uninstalled=$(awk -F"$tab" -v category="$crowded" '$1 == category { print $2; exit }' <<<"$dock_declaration")
rm -rf "${machine:?}/DockApps/$uninstalled.app"
dock_plist "$(dock_expected_tiles)"
report=$(drift)
silent "$report" 'Dock layout' 'says nothing about a tile whose application is not installed'

# And a category emptied by that same absence takes its separator with it, rather than
# leaving a stray one behind. Both sequences are read out of the report, so this asks the
# command what it expects rather than asking the fixture what it was given.
expected_sequence() {
  sed -n 's/^ *expected: //p' <<<"$1"
}
separators() {
  awk -F'|' '{ print NF - 1 }' <<<"$1"
}
dock_plist ''
report=$(drift)
crowded_sequence=$(expected_sequence "$report")
lonely=$(awk -F"$tab" '{ seen[$1]++; first[$1] = first[$1] == "" ? $2 : first[$1] } END { for (c in seen) if (seen[c] == 1) { print first[c]; exit } }' \
  <<<"$dock_declaration")
rm -rf "${machine:?}/DockApps/$lonely.app"
report=$(drift)
lonely_sequence=$(expected_sequence "$report")
check "$(separators "$lonely_sequence")" "$(($(separators "$crowded_sequence") - 1))" \
  'drops the separator of a category nothing is left in'
silent "$lonely_sequence" "$lonely" 'drops the application with it'
mkdir -p "$machine/DockApps/$lonely.app" "$machine/DockApps/$uninstalled.app"

# A folder's display options are part of its tile, and `dockutil --list` does not report
# them — which is why the command reads the Dock's preferences instead.
folder_row=$(head -1 <<<"$dock_folder_declaration")
folder_label=$(basename "$(cut -f1 <<<"$folder_row")")
folder_view=$(cut -f2 <<<"$folder_row")
folder_sort=$(cut -f3 <<<"$folder_row")
folder_display=$(cut -f4 <<<"$folder_row")
bent_sort=$(awk -F"$tab" -v declared="$folder_sort" \
  '$1 == "sort" && $2 != declared { print $2; exit }' <<<"$dock_option_codes")
dock_plist "$(dock_expected_tiles |
  sed "s|${tab}${folder_view}${tab}${folder_sort}${tab}|${tab}${folder_view}${tab}${bent_sort}${tab}|")"
report=$(drift)
says "$report" 'Dock layout' 'reports a folder that stopped sorting the way it is declared'
says "$report" "$folder_label($folder_view, $bent_sort, $folder_display)" \
  'names the sort order it found'

dock_plist "$(dock_expected_tiles)"

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
