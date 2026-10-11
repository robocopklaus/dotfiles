# The managed defaults, rendered from `.chezmoidata/macos-defaults.toml` — the
# one declaration System settings phase's defaults script and `drift` both derive from (ADR 0002). Included at
# render time, so the defaults script's `run_onchange_` hash moves whenever the table does.
#
# Two calls are the whole interface: `managed_defaults_diverged` says which entries the
# machine disagrees with, and `managed_default_apply` writes one of them back. Everything
# else here — the table, the scope flag, and the two spellings a boolean has — is how
# those two work, and no caller reaches past them. A caller that picked a spelling once
# wrote the read one, and a converged machine never writes, so nothing caught it until a
# single boolean drifted on a live Mac.
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

# Every entry the machine disagrees with, one tab-separated line each: scope, domain, key,
# label, the expected value and the current one. An entry is named by all three of scope,
# domain and key, because tap-to-click is declared twice and only the scope tells the two
# apart. The current value comes last because it is the one field that can be empty — an
# unset key — and `read` with a tab separator folds an empty field anywhere else into the
# next one.
managed_defaults_diverged() {
  local domain key type value scope expected current
  while IFS=$'\t' read -r domain key type value scope; do
    [ -n "$domain" ] || continue
    expected=$(managed_default_expected "$type" "$value")
    current=$(managed_default_current "$scope" "$domain" "$key")
    [ "$current" = "$expected" ] && continue
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$scope" "$domain" "$key" \
      "$(managed_default_label "$scope" "$domain")" "$expected" "$current"
  done <<<"$managed_defaults"
}

# Writes one entry back as declared, in the spelling `defaults write` accepts. Asked by
# name rather than handed a value, so the declared value never passes through the caller.
# An entry the table does not hold is refused rather than guessed at.
managed_default_apply() {
  local want_scope=$1 want_domain=$2 want_key=$3 domain key type value scope
  while IFS=$'\t' read -r domain key type value scope; do
    if [ "$scope" = "$want_scope" ] && [ "$domain" = "$want_domain" ] && [ "$key" = "$want_key" ]; then
      managed_defaults_run "$scope" write "$domain" "$key" "-$type" "$(managed_default_written "$value")"
      return
    fi
  done <<<"$managed_defaults"
  printf 'managed_default_apply: %s %s %s is not a managed default\n' \
    "$want_scope" "$want_domain" "$want_key" >&2
  return 1
}
