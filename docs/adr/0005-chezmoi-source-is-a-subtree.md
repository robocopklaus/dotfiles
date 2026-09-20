# The chezmoi source is a subtree, not the repository root

A `.chezmoiroot` file containing `home` confines the chezmoi source to `home/`. Everything chezmoi reads lives under it; everything else — the Brewfile, the ADRs, the CI workflows, the bats suite — sits at the repository root, structurally out of reach of `$HOME`.

The prior setup made the repository root the source and excluded the rest with `.chezmoiignore`. That is a denylist, and a denylist fails open: the file you forget to list is the file that lands in `$HOME`. It cost four lines when the repository held four non-dotfile assets. This repository holds a growing `docs/adr/`, `.github/workflows/`, a test suite, a drift command and a defaults declaration, and every one of them would be another line that must not be forgotten. `.chezmoiroot` inverts the default: only what is placed under `home/` can ever reach `$HOME`, and `.chezmoiignore` is deleted outright.

## Considered options

**Keep the flat root and maintain `.chezmoiignore`.** Rejected on the direction of its failure. Both arrangements can express the same tree; they differ in what happens when a human forgets. A forgotten ignore line writes an unexpected file into `$HOME`, silently. A file forgotten *outside* `home/` simply is not applied, which is visible and harmless.

**Move only the non-dotfile assets into a subdirectory** — `meta/`, or similar — leaving the source at the root. Rejected. It is the same denylist with a longer prefix: the root remains in range, so anything added there is still applied by default.

## Consequences

`CHEZMOI_SOURCE_DIR` points at `home/`, not at the repository root, so a script cannot reach a root-level asset at **runtime**. This is not the limitation it first appears to be. Templates resolve `include` against the source directory and `../` escapes it cleanly, failing loudly with the resolved absolute path when the target is missing — so root-level assets are reached at **render** time instead, which is where this repository wants them anyway. The Brewfile is inlined into the packages script and piped to `brew bundle --file=-`, which deletes both the old runtime `$CHEZMOI_SOURCE_DIR` lookup and the separate `sha256` change-detection comment: the content is in the rendered script, so `run_onchange_` re-triggers on an edit by construction.

Shared shell is a `.chezmoitemplates` include rather than a file sourced at runtime, for the same reason and two sharper ones. `run_onchange_` hashes the rendered script, so a sourced helper could be edited without re-running any of its consumers — a correctness failure, not an aesthetic one. And ADR 0004 lints *rendered* scripts, where `source` of a runtime path is unfollowable by shellcheck, which would make the shared helper the one piece of shell CI never checks. Inlining puts it under the linter at every call site, and lets `dot_zprofile` include the identical text — collapsing a three-way duplication rather than a two-way one.

The declaration of managed macOS defaults lives under `home/.chezmoidata/`, so chezmoi loads it into the template data context and both the applying script and the drift command read the one declaration ADR 0002 requires. This deliberately separates the two surfaces a human edits during the annual review: the Brewfile at the root, the defaults table nested. The mechanism follows the difference between a file piped verbatim to a tool and data consumed by two templates.
