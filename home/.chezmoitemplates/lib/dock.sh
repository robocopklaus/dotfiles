# The Dock declaration of §6.4, rendered from `.chezmoidata/dock.toml` — the one
# declaration the P6 layout script and `drift` both reconcile against (ADR 0009).
# Included at render time, so 61's `run_onchange_` hash moves whenever the declaration
# does, and the check and the application stay one mechanism rather than two lists.

# One tab-separated line per application: the category it sits in, then its bundle name.
# The category is carried rather than the spacer, because the spacer is generated.
dock_declared=$(
  cat <<'DOCK_DECLARED'
{{ range .dock.categories -}}
{{ $category := .name -}}
{{ range .apps }}{{ $category }}	{{ . }}
{{ end -}}
{{ end -}}
DOCK_DECLARED
)

# One line per folder: its path, then the display options its tile carries, in dockutil's
# spelling.
dock_folders=$(
  cat <<'DOCK_FOLDERS'
{{ range .dock.folders }}{{ .path }}	{{ .view }}	{{ .sort }}	{{ .display }}
{{ end -}}
DOCK_FOLDERS
)

# Where a declared bundle name is looked for, in order. Two roots and no third: an
# application somewhere else is not one this repository installs.
dock_app_roots=$(
  cat <<'DOCK_APP_ROOTS'
/Applications
/System/Applications
DOCK_APP_ROOTS
)

# What the Dock stores for a folder option, against the word dockutil is given for it.
# One table rather than six functions, and it is read in one direction only — the
# declaration speaks words, the plist answers numbers, and the report wants words back.
dock_option_codes=$(
  cat <<'DOCK_OPTION_CODES'
view	auto	0
view	fan	1
view	grid	2
view	list	3
sort	name	1
sort	dateadded	2
sort	datemodified	3
sort	datecreated	4
sort	kind	5
display	stack	0
display	folder	1
DOCK_OPTION_CODES
)

# A code the Dock stores, back in the word the declaration uses. An unknown code is
# printed as it came: a Dock holding a value nothing declares is a mismatch to report,
# not an error to die on.
dock_option_word() {
  local option=$1 code=$2
  awk -F'\t' -v option="$option" -v code="$code" \
    '$1 == option && $3 == code { print $2; found = 1 } END { exit !found }' \
    <<<"$dock_option_codes" || printf '%s\n' "$code"
}

# The path the Dock itself stores, which is the bundle with every symlink resolved:
# Safari is declared as the `/Applications/Safari.app` a human would name and lands in
# the Dock under the cryptex path that one points at. Both sides of the comparison go
# through here, so the two spellings of one bundle can never read as a mismatch — which
# would rebuild the Dock on every single run.
dock_resolve() {
  realpath "$1" 2>/dev/null || printf '%s\n' "$1"
}

# Where a declared name lives on this machine, or nothing if it is not installed.
dock_app_path() {
  local name=$1 root
  while IFS= read -r root; do
    [ -d "$root/$name.app" ] || continue
    dock_resolve "$root/$name.app"
    return 0
  done <<<"$dock_app_roots"
  return 1
}

# The declaration **rendered** against this machine: an application that is not installed
# drops out, and a spacer follows every category that still has a member. This is the
# sequence both the reconcile and the drift report compare against (§7) — comparing
# against the raw declaration would report a missing cask twice, once truthfully as a
# package and once misleadingly as layout drift.
#
# The folders are unconditional. They close the sequence, and a directory that is not
# there is a machine to fix rather than a tile to drop.
dock_expected_sequence() {
  local category name path previous='' folder view sort display

  while IFS=$'\t' read -r category name; do
    [ -n "$category" ] || continue
    path=$(dock_app_path "$name") || continue
    if [ -n "$previous" ] && [ "$category" != "$previous" ]; then
      printf 'spacer\n'
    fi
    previous=$category
    printf 'app\t%s\n' "$path"
  done <<<"$dock_declared"
  [ -z "$previous" ] || printf 'spacer\n'

  while IFS=$'\t' read -r folder view sort display; do
    [ -n "$folder" ] || continue
    # The one token a declared path may carry, expanded here so the path handed to
    # dockutil and the path compared against are produced by the same line.
    folder=${folder//\$\{HOME\}/$HOME}
    printf 'folder\t%s\t%s\t%s\t%s\n' "$(dock_resolve "$folder")" "$view" "$sort" "$display"
  done <<<"$dock_folders"
}

# A `file://` URL from the plist, back to the path it names. The Dock percent-encodes,
# and `%b` decodes the escape the substitution turns each triplet into.
dock_url_path() {
  local url=${1#file://}
  url=${url%/}
  printf '%b\n' "${url//%/\\x}"
}

# What the Dock holds, in the same shape. Read from the Dock's own preferences rather
# than from `dockutil --list`: that listing names the tiles in order but not the folders'
# view, sort and display, and a folder that stopped sorting by date added is a mismatch
# like any other. `plutil` reports an array's length for the array itself, which is what
# makes a plist carrying data blobs — the Dock's bookmarks — walkable without jq.
#
# Exits non-zero when the preferences could not be read at all, which is a question the
# machine did not answer rather than an empty Dock.
dock_current_sequence() {
  local plist index count type url showas arrangement displayas

  plist=$(mktemp) || return 1
  if ! defaults export com.apple.dock "$plist" 2>/dev/null; then
    rm -f "$plist"
    return 1
  fi

  count=$(plutil -extract 'persistent-apps' raw -o - "$plist" 2>/dev/null) || count=0
  for ((index = 0; index < count; index++)); do
    type=$(plutil -extract "persistent-apps.$index.tile-type" raw -o - "$plist" 2>/dev/null) || type=''
    case $type in
      *spacer-tile)
        printf 'spacer\n'
        ;;
      *)
        url=$(plutil -extract "persistent-apps.$index.tile-data.file-data._CFURLString" raw -o - "$plist" 2>/dev/null) || url=''
        printf 'app\t%s\n' "$(dock_resolve "$(dock_url_path "$url")")"
        ;;
    esac
  done

  count=$(plutil -extract 'persistent-others' raw -o - "$plist" 2>/dev/null) || count=0
  for ((index = 0; index < count; index++)); do
    url=$(plutil -extract "persistent-others.$index.tile-data.file-data._CFURLString" raw -o - "$plist" 2>/dev/null) || url=''
    showas=$(plutil -extract "persistent-others.$index.tile-data.showas" raw -o - "$plist" 2>/dev/null) || showas=''
    arrangement=$(plutil -extract "persistent-others.$index.tile-data.arrangement" raw -o - "$plist" 2>/dev/null) || arrangement=''
    displayas=$(plutil -extract "persistent-others.$index.tile-data.displayas" raw -o - "$plist" 2>/dev/null) || displayas=''
    printf 'folder\t%s\t%s\t%s\t%s\n' \
      "$(dock_resolve "$(dock_url_path "$url")")" \
      "$(dock_option_word view "$showas")" \
      "$(dock_option_word sort "$arrangement")" \
      "$(dock_option_word display "$displayas")"
  done

  rm -f "$plist"
}

# A sequence as a report prints it: the bundle name for an application, a bar for a
# spacer, and a folder with the options that are part of its tile. Both the reconcile and
# `drift` print the pair, and printing both sequences gives the same information as a
# per-tile diff for a fraction of the shell (ADR 0009).
dock_sequence_label() {
  local kind first second third fourth line=''
  while IFS=$'\t' read -r kind first second third fourth; do
    case $kind in
      app) line+=" $(basename "$first" .app)" ;;
      spacer) line+=' |' ;;
      folder) line+=" $(basename "$first")($second, $third, $fourth)" ;;
    esac
  done <<<"$1"
  printf '%s\n' "${line# }"
}
