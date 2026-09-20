# The managed defaults, rendered from `.chezmoidata/macos-defaults.toml` — the
# one declaration the P6 script and `drift` both derive from (ADR 0002). Included at
# render time, so the P6 script's `run_onchange_` hash moves whenever the table does.
#
# One tab-separated line per entry: domain, key, type, expected value, and the scope —
# `currentHost` for the one key macOS keeps per machine, `any` for every other. The scope
# is asked for with `hasKey` because only that one entry declares it; chezmoi treats a
# missing key as an error rather than as false.
managed_defaults=$(
  cat <<'MANAGED_DEFAULTS'
{{ range .macosDefaults -}}
{{ .domain }}	{{ .key }}	{{ .type }}	{{ .value }}	{{ if hasKey . "currentHost" }}currentHost{{ else }}any{{ end }}
{{ end -}}
MANAGED_DEFAULTS
)

# `defaults` takes the scope as a flag before the verb. Branching here rather than at each
# call site means the one entry that carries a scope is handled once.
managed_defaults_run() {
  local scope=$1
  shift
  if [ "$scope" = 'currentHost' ]; then
    defaults -currentHost "$@"
  else
    defaults "$@"
  fi
}

# What is handed to `defaults write`, which is the declared value with `${HOME}` expanded
# and nothing else. `-bool` takes `true`/`false`/`yes`/`no` and rejects `1`/`0` with its
# usage text and exit 255 — the exact opposite of the spelling `defaults read` answers in,
# so the two cannot share one function. Expanding here, on the way in, is what keeps the
# string written and the string compared against produced by the same line.
managed_default_written() {
  local value=$1
  # The token is escaped rather than single-quoted so that the linter CI runs over these
  # rendered scripts reads it as the literal it is, instead of as an expansion
  # someone forgot to quote properly.
  printf '%s\n' "${value//\$\{HOME\}/$HOME}"
}

# What the machine should hold, in the spelling `defaults read` answers in: booleans come
# back as 1 and 0.
managed_default_expected() {
  local type=$1 value=$2
  value=$(managed_default_written "$value")
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
#
# `defaults` itself is not guarded the way `drift` guards `brew`, `mas` and `chezmoi`
#. Those are installed software and can genuinely be absent; this is macOS, in the
# same class as `sed` and `pkgutil`, which are not guarded either. And the two failures
# point opposite ways: a `defaults` that could not run reports every managed key as
# disagreeing, which is loud and sends you to re-run the bootstrap, where it would fail
# again just as loudly. Under-reporting is the failure `drift` will not have quietly.
managed_default_current() {
  local scope=$1 domain=$2 key=$3
  managed_defaults_run "$scope" read "$domain" "$key" 2>/dev/null || true
}

# How an entry is named in a report: the domain, plus the scope when it has one, because
# tap-to-click is declared twice and only the scope tells the two apart.
managed_default_label() {
  local scope=$1 domain=$2
  if [ "$scope" = 'currentHost' ]; then
    printf '%s -currentHost\n' "$domain"
  else
    printf '%s\n' "$domain"
  fi
}
