# Managed configuration is hand-authored plain text, and nothing else

The repository manages an application's configuration as a file when that file is plain text and its content is predominantly human-authored. Nothing else is managed: not machine-written state, not secrets, and not settings that exist only inside a vendor's account.

The prior setup had no stated rule. It managed the twelve config paths that happened to be noticed, and the question "why is Raycast not in here" had no answer beyond nobody having tried. A rule is what makes the January review cheap: a file is in or out by a property of the file, and the reasoning does not have to be reconstructed.

The criterion has three clauses, and all three are load-bearing:

- **Plain text.** Not a feasibility nicety. Raycast's settings are hand-authored in every meaningful sense, but they live in an encrypted, device-bound SQLite store; no criterion can override the absence of a file to commit.
- **Human content dominates.** Several real files have two authors. `~/.claude/settings.json` is written by its application — that is what the `.bak` beside it is — yet 4 KB of permissions and hooks are the human's. `~/.config/gh/config.yml` is generated boilerplate around exactly one human line, `co: pr checkout`, and `~/.codex/config.toml` carries four hand-written lines under ninety-seven machine-appended ones. Dominance separates them; authorship alone cannot.
- **Never a secret, whatever its shape.** `~/.ha-cli.env`, `~/.cloudflare`, `~/.firefly_token` and `~/.ghostfolio_token` are plain text and entirely hand-placed. They satisfy the first two clauses completely. Only this clause stops the repository from committing a Cloudflare token.

The third clause restates ADR 0003 at the level of an individual file, deliberately and redundantly. A rule that requires a second document in order to avoid a catastrophic reading is not a rule.

Where the criterion says no, the reason is recorded in one of three forms, and the distinction is documentary rather than mechanical — the repository does the same thing in all three cases, which is nothing:

- **Account-restored** — the settings return by signing in. Raycast, Slack, Chrome, ChatGPT, Mimestream, Clockify, WhatsApp, 1Password.
- **Out of scope** — the configuration belongs to data this effort does not restore. Obsidian, whose four vaults all live under `~/Development/` and whose per-vault `.obsidian/` directories are already versioned with their own repositories; what remains at application level is a registry of absolute paths into those directories.
- **Accepted lost** — a deliberate write-off. `gh`'s single alias, `codex`'s four lines.

The domain of the rule is the inventory from the content review, and a configuration inherits the group of its entry: client-tool configuration rides the client flag, base rides the base.

## Considered options

**Three mechanisms for the three outcomes** — managed, deferred to the application's own sync, unmanaged. Rejected because two of the three are the same mechanism. From the bootstrap's position, "the application will sync it" and "it is gone" are both *the repository does nothing*; the difference is an expectation, not a behaviour. Encoding an expectation as a category invents a distinction the code cannot express, and produces the second source of truth that the separate inventory document was already rejected for.

**Manage only files the application never writes.** Rejected: it is the clean version of the dominance clause and it deletes the best-earned entry in the set. `claude/settings.json` would become unmanaged in order to protect a principle, discarding 4 KB of deliberate configuration because its owner occasionally appends to it. Write-back is not a disqualification, it is drift, and ADR 0002's report already exists to surface drift. The re-adoption is a deliberate `chezmoi add`.

**Draw the boundary at a directory** — `~/.config` and `$HOME` only. Rejected as arbitrary. It would exclude Cursor's `settings.json`, five hand-written keys that satisfy every clause, for the sole reason that it sits under `~/Library/Application Support/`. The boundary belongs at a property of the file, applied identically wherever the file lives.

**Cover the machine's whole configuration surface** rather than the inventory. Rejected because that set is unbounded and therefore cannot be honest. `~/.config` holds directories from tools that were cut (`gws`), from client tooling, and from tools that were never inventoried at all — `cagent`, `zerolib`, `tanstack`, `configstore` — each dropped in passing by a one-shot runner. Any `uvx` invocation can add a row, so a table claiming completeness would be false on the day it was written.

## Consequences

The criterion's second clause trades a measurement for a judgement. The content review's bar was "it left a trace", checkable by anyone; "the human content dominates" is an eyeball call. This is accepted because every alternative rule is worse and the set is roughly a dozen small files, but it is the clause that will need re-reading if the set ever grows.

Reasons live in the specification's table, not inside the managed files. The Brewfile's trailing-comment convention does not transfer: these are files rather than list entries, they have no common comment syntax, and several are JSON, where a comment is a syntax error. For the same reason there is no CI check — the Brewfile check enforces presence in one file with one syntax, and no equivalent shape exists here.

The closing report's static tail, which ADR 0003 reserved for sign-ins that other things depend on, widens to admit two more sections: the account-restored applications, and the credential *paths* the command-line tools expect — paths only, never values, so a rebuild states that `ha` will want `~/.ha-cli.env` from 1Password. Most of the account-restored list is depended on by nothing; Slack and WhatsApp block no phase. The tail's admission rule therefore changes from *what the bootstrap needs* to *what the human would otherwise discover months later*, which is the cost of this decision and is stated rather than slipped in.

Neither new section is verified. That is deliberate, and it is not in tension with ADR 0002: the drift command re-derives state because it checks the machine against what the repository *declares*, and whether a vendor considers a machine signed in is not a declaration. Probing it would mean a bespoke, undocumented marker check per application, each one changeable without notice by its vendor and failing toward false alarms. The human is at the keyboard signing in regardless, and is the better checker.

Credential files are not preflight gates. They block a command-line tool, never a later phase, and gates were reserved for what the bootstrap depends on.

Installed agent skills and plugins are outside this decision. They are not configuration but installed artifacts — a third package source alongside Homebrew and the App Store, which the content review never covered — and they are settled separately.

`~/.config/gws` belongs to a tool cut four months ago, and nothing on the machine will ever remove it. Confining the rule to the inventory means such residue is not tracked, not cleaned, and not pretended about; the rebuild is what collects it. That is an argument for the annual wipe rather than a gap in this decision.
