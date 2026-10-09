# The run's progress view: one line per thing done, the detail folded away unless it
# failed or was asked for (ADR 0017). Every phase includes this and draws itself — chezmoi
# runs each one as its own process, so nothing lives long enough to own the terminal.
#
# Plain bash and ANSI escapes, and no tool to draw with: the gate includes this before
# Homebrew exists, and a drawing tool would have to join the trust chain to be there.
#
# The one switch is whether stdout is a terminal, derived from the machine rather than
# from a flag. Without one — CI, a redirect — nothing is folded and no escape is written,
# so the output is what the tools printed. With one, `chezmoi apply --verbose` sets
# `CHEZMOI_VERBOSE` in every script it runs, and that unfolds everything.
if [ -t 1 ]; then
  ui_bold=$'\033[1m'
  ui_dim=$'\033[2m'
  ui_green=$'\033[32m'
  ui_red=$'\033[31m'
  ui_reset=$'\033[0m'
else
  ui_bold='' ui_dim='' ui_green='' ui_red='' ui_reset=''
fi
if [ -t 1 ] && [ -z "${CHEZMOI_VERBOSE:-}" ]; then
  ui_folded=yes
else
  ui_folded=''
fi

# A phase's header, and the epilogue's banners.
ui_header() {
  printf '\n%s%s%s\n' "$ui_bold" "$1" "$ui_reset"
}

ui_ok() {
  printf '  %s✓%s %s\n' "$ui_green" "$ui_reset" "$1"
}

# A failed item, with the remedy that fixes it beneath it when there is one.
ui_fail() {
  printf '  %s✗%s %s\n' "$ui_red" "$ui_reset" "$1"
  [ -z "${2:-}" ] || printf '    %s\n' "$2"
}

# Detail that belongs to the line above it.
ui_note() {
  printf '    %s%s%s\n' "$ui_dim" "$1" "$ui_reset"
}

# Runs `"$@"` as one line labelled `$1`, and returns its status.
#
# Folded, its output goes to a temporary file that lives only as long as the step: nothing
# survives the run, so nothing is left to go stale when a skipped `run_onchange_` phase
# does not overwrite it. A failure prints the tail of that file. The command reads from
# /dev/null, so one that wanted input fails and unfolds rather than waiting behind a
# spinner for an answer nobody can see it asking for.
#
# The command runs where `set -e` does not reach — bash suspends it for anything whose
# status is being tested — so a step that is a function must return its own failures.
ui_step() {
  local label=$1 log spinner status=0
  shift

  if [ -z "$ui_folded" ]; then
    printf '  ▸ %s\n' "$label"
    "$@" || status=$?
  else
    log=$(mktemp) || return
    ui_spin "$label" "$log" &
    spinner=$!
    "$@" >"$log" 2>&1 </dev/null || status=$?
    kill "$spinner" 2>/dev/null || true
    wait "$spinner" 2>/dev/null || true
    printf '\r\033[K'
  fi

  if [ "$status" -eq 0 ]; then
    ui_ok "$label"
  else
    ui_fail "$label"
    if [ -n "$ui_folded" ]; then
      tail -n 20 "$log" | while IFS= read -r line; do ui_note "$line"; done
      ui_note 'The whole output: chezmoi apply --verbose'
    fi
  fi
  [ -z "$ui_folded" ] || rm -f "$log"
  return "$status"
}

# The spinner, in the background of a folded step. It stops when the script it draws for
# is gone — a background job ignores the interrupt that ended it — and takes the step's
# temporary file with it, since the script that would have deleted it no longer can.
ui_spin() {
  local label=$1 log=$2 frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏) i=0
  while kill -0 "$$" 2>/dev/null; do
    printf '\r  %s %s' "${frames[i]}" "$label"
    i=$(((i + 1) % ${#frames[@]}))
    sleep 0.1
  done
  rm -f "$log"
}
