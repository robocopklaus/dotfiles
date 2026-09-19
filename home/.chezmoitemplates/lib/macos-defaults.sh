# The managed defaults of §6.4, rendered from `.chezmoidata/macos-defaults.toml` — the
# one declaration the P6 script and `drift` both derive from (ADR 0002). Included at
# render time, so the P6 script's `run_onchange_` hash moves whenever the table does.
#
# One tab-separated line per entry: domain, key, type, expected value, and the host scope
# — `currentHost` for the one key macOS keeps per machine, `any` for every other. The
# scope is asked for with `hasKey` because only that one entry declares it; chezmoi
# treats a missing key as an error rather than as false.
managed_defaults=$(
  cat <<'MANAGED_DEFAULTS'
{{ range .macosDefaults -}}
{{ .domain }}	{{ .key }}	{{ .type }}	{{ .value }}	{{ if hasKey . "currentHost" }}currentHost{{ else }}any{{ end }}
{{ end -}}
MANAGED_DEFAULTS
)

# `defaults` takes the host scope as a flag before the verb. Branching here rather than
# at each call site means the one entry that carries a scope is handled once.
managed_defaults_run() {
  local host=$1
  shift
  if [ "$host" = 'currentHost' ]; then
    defaults -currentHost "$@"
  else
    defaults "$@"
  fi
}

# What the machine should hold, in the spelling `defaults read` answers in: booleans come
# back as 1 and 0, and `${HOME}` is expanded here so the value written and the value
# compared against are produced by the same line.
managed_default_expected() {
  local type=$1 value=$2
  # The token is escaped rather than single-quoted so that the linter CI runs over these
  # rendered scripts (§8) reads it as the literal it is, instead of as an expansion
  # someone forgot to quote properly.
  value=${value//\$\{HOME\}/$HOME}
  if [ "$type" = 'bool' ] && [ "$value" = 'true' ]; then
    printf '1\n'
  elif [ "$type" = 'bool' ]; then
    printf '0\n'
  else
    printf '%s\n' "$value"
  fi
}

# What the machine holds, or nothing at all. `defaults` exits non-zero for a key it has
# never been given, which is a value that disagrees like any other rather than an error —
# and no managed value is the empty string, so the two cannot be confused.
managed_default_current() {
  local host=$1 domain=$2 key=$3
  managed_defaults_run "$host" read "$domain" "$key" 2>/dev/null || true
}

# How an entry is named in a report: the domain, plus the scope when it has one, because
# tap-to-click is declared twice and only the scope tells the two apart.
managed_default_scope() {
  local host=$1 domain=$2
  if [ "$host" = 'currentHost' ]; then
    printf '%s -currentHost\n' "$domain"
  else
    printf '%s\n' "$domain"
  fi
}
