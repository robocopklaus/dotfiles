# Homebrew, acquired if it is absent and put on the calling script's PATH either way.
# Two call sites want this, in different phases — the gate, which acquires the trust
# chain before it verifies it, and the Packages phase, which acquires everything else — so the fetch is
# written once here rather than twice (ADR 0005). It draws its line with `lib/ui.sh`,
# which every caller has already included.
{{ template "lib/homebrew.sh" . }}
if ! command -v brew >/dev/null 2>&1; then
  # Fetched into a variable first, so a failed download aborts here. Piped straight into
  # bash it would be invisible: the substitution yields an empty script that exits 0.
  installer=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
  ui_step 'Homebrew' env NONINTERACTIVE=1 /bin/bash -c "$installer"
  # The installer's own prefix on Apple Silicon, which is the only architecture the gate
  # admits — not a second cascade.
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
