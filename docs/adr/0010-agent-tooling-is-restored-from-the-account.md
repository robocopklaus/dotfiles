# Agent tooling is restored from the account, not declared

The repository declares **no** agent skills and **no** plugins. The claude.ai account is the restore mechanism: skills and plugins enabled there sync down to `~/.claude/skills/synced/` and `~/.claude/plugins/synced/` after login, refresh themselves roughly every ten minutes, and require no local declaration to load. A wipe costs nothing, because nothing on the agent-tooling surface was ever local truth.

This is the same shape as the secrets decision: zero declarations, with one named exception if it proves necessary.

An entry belongs in the **cheapest mechanism that can hold it**, measured in what a rebuild has to do to restore it:

| Mechanism | Cost to the rebuild | Kept current by |
| --- | --- | --- |
| The claude.ai account | none — syncs after login | itself, continuously |
| The project's own `.claude/settings.json` | none here — repositories are out of scope | the project, in version control |
| This repository | a bootstrap step and an annual review line | hand |

This repository therefore declares only what neither of the first two can hold. On the agent-tooling surface that set is currently empty.

The second row carries an unstated precondition: a project's `.claude/settings.json` travels with the clone only where the project is a clone. `~/Development/21st-brain` is not — it is an empty directory holding nothing but `.claude/`, created as a scope anchor and backed by no remote. Nothing pinned to it survives a wipe. This does not change the decision, because the entry pinned there is carried by the first row instead, but it is why the row is a claim about repositories and not about directories.

Scope follows the domain, not the habit: tooling that applies regardless of what is being worked on is enabled on the account; tooling that only makes sense inside one domain is installed `--scope project`, which writes to that project's checked-in `.claude/settings.json` and travels with the clone. `mattpocock-skills` is domain-independent and belongs to the account. The Cloudflare set and the Obsidian plugin are domain-specific and belong to the projects that use them.

Claude Code is the only agent this repository provisions. `~/.cursor/skills/` is Cursor's surface and is not managed.

## Considered options

**Declaring plugins in the managed `~/.claude/settings.json` and installing them in P7.** Rejected once the account was measured to carry third-party marketplace plugins, not merely Anthropic's own — private repositories included. The declaration would be a second list beside the account's, kept in step by hand, and it would buy a phase-7 script whose entire job is to reproduce a state the login already reproduces. It also does not work on its own terms: there is no documented restore-from-declaration flow, so the script would have to walk `enabledPlugins` and shell out to `claude plugin install` per entry — bootstrap code written to compensate for a mechanism that was already free.

**Declaring the skills as managed files, the way configuration is managed.** Rejected by the criterion in ADR 0006: a skill is an *installed artifact*, not hand-authored configuration. Committing 14 vendored copies of somebody else's repository would freeze them at the commit they were copied, and the whole point of the account path is that it updates.

**Keeping the loose copies in `~/.claude/skills/` and accepting them as lost.** Rejected as a decision, accepted as an outcome. The copies genuinely are lost at the wipe and nothing has to be written to make that happen — but leaving it there would answer the ticket with a shrug. The set is domain-specific tooling in a global directory, which is why it sat unused and undeclared for four months; it is re-scoped to the projects that need it rather than mourned.

**Managing `~/.cursor/skills/` alongside Claude Code's.** Rejected. Claude Code reads only `~/.claude/` and a project's `.claude/`; it has no knowledge of the Cursor path. Managing both would store one set of skills twice and keep them in step by hand — the two-lists-one-truth failure this repository rejects everywhere else.

**Giving the drift report a section for skills and plugins.** Rejected as vacuous. ADR 0002 compares the machine against the repository's declarations, and the repository declares nothing here, so the section would have nothing to compare. The account's own state is the account's business.

## Consequences

`enabledPlugins` and `extraKnownMarketplaces` are **removed** from the managed `~/.claude/settings.json`. Three plugin entries and four marketplace entries move to the account. The managed file gets smaller, and the surface it covers stops overlapping the account's.

The annual review gains no entries here, and loses the question entirely. "Does this skill still earn its place?" is asked on claude.ai against the account, at whatever moment it is noticed — it is no longer a line item in a file this repository has to reason about in January.

Curating the account becomes a real responsibility, and it is the one thing this decision depends on. A plugin that is installed locally and never enabled on the account does not survive a wipe, silently. This is the same failure the map exists to end, moved one level up — so enabling on the account, not installing locally, is the default act.

Five of the eight plugin installs on the live machine are project-scoped, pinned to repositories under `~/Development`. They restore with those repositories, which are out of scope, and this repository says nothing about them.

The Obsidian plugin is installed twice on the live machine — user-scoped *and* project-scoped across four vaults. That duplication is the measured evidence that an unstated scope rule produces drift on its own, and it is what the domain criterion above exists to prevent.

The one candidate exception is closed, and there is no exception. `skills-leadership` is a private repository, and the account carries it: registered from claude.ai as `21stdigital/skills-leadership`, it reached `~/.claude/plugins/synced/` in about thirteen minutes and loads as `leadership-toolkit@synced`. The ticket's premise — that nothing obvious would hold the credentials — had an answer the local setup obscured. The local declaration reaches the repository over SSH; claude.ai reaches it over its own GitHub authorization, and records the source as `github` rather than the SSH URL. The credential was never the marketplace's property, only the client's.

That fixes the boundary of this decision more precisely than "private or public": the account path is a **GitHub** path. A marketplace on a private host that is not GitHub has no demonstrated route onto the account, and would be the next candidate for a named exception. There is none today.

So this repository declares nothing on the agent-tooling surface, without qualification, and `extraKnownMarketplaces` leaves the managed `settings.json` with no entry held back.
