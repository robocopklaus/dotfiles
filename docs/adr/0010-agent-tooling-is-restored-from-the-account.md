# Agent tooling is restored from the account, not declared

The repository declares **no** agent skills and **no** plugins. The claude.ai account is the restore mechanism: a marketplace **registered on the account**, and the plugins enabled from it, sync down to `~/.claude/skills/synced/` and `~/.claude/plugins/synced/` after login, refresh themselves without being asked, and require no local declaration to load. A wipe costs nothing, because nothing on the agent-tooling surface was ever local truth.

*Registered* is the load-bearing word, and it is not the word this decision was first written with. See *The account carries the source* below, which is what the first rebuild under this decision cost to learn.

This is the same shape as the secrets decision: zero declarations, with one named exception if it proves necessary.

An entry belongs in the **cheapest mechanism that can hold it**, measured in what a rebuild has to do to restore it:

| Mechanism | Cost to the rebuild | Kept current by |
| --- | --- | --- |
| The claude.ai account | none — syncs after login | itself, continuously |
| The project's own `.claude/settings.json` | none here — repositories are out of scope | the project, in version control |
| This repository | a bootstrap step and an annual review line | hand |

This repository therefore declares only what neither of the first two can hold. On the agent-tooling surface that set is currently empty.

The second row carries an unstated precondition: a project's `.claude/settings.json` travels with the clone only where the project is a clone. `~/Development/21st-brain` is not — it is an empty directory holding nothing but `.claude/`, created as a scope anchor and backed by no remote. Nothing pinned to it survives a wipe. This does not change the decision, because the entry pinned there is carried by the first row instead, but it is why the row is a claim about repositories and not about directories.

It carries a second one, and the table's `none` is only true where that one holds too: the clone brings the *enablement*, not the *source*. A checked-in `.claude/settings.json` that names `"obsidian@obsidian-skills": true` says nothing about where `obsidian-skills` is fetched from, and on a fresh machine that enablement points at nothing. A project is self-supporting only when it checks in `extraKnownMarketplaces` beside `enabledPlugins`. Measured: `mi-casa` and `vault` check in the enablement and not the source, so the registration they depend on lives only in one machine's user settings. Repositories remain out of scope, so this is reported rather than repaired — but the row may not claim a cost of none without naming the condition.

Scope follows the domain, not the habit: tooling that applies regardless of what is being worked on is enabled on the account; tooling that only makes sense inside one domain is installed `--scope project`, which writes to that project's checked-in `.claude/settings.json` and travels with the clone. `mattpocock-skills` is domain-independent and belongs to the account. The Cloudflare set and the Obsidian plugin are domain-specific and belong to the projects that use them.

## The account carries the source

The account carries the **source**; the project carries the **selection**. A marketplace
wanted on more than one machine, or by more than one project, is registered on the
account. Which plugins are on where stays in the project's checked-in
`.claude/settings.json`. Registering a marketplace is not enabling a plugin: it says only
that a source is known, and it is the half that a second machine cannot reconstruct for
itself.

This is not how the decision was first written, and the difference cost a rebuild.
`mattpocock-skills` was installed user-scoped and enabled — it loaded every day — while
`anthropics/claude-plugins-official` was registered nowhere. There was no route for it to
travel, so the Mac Studio came up without it, silently, and it was noticed by hand weeks
later when the skill was reached for. The original text said *enabled on the account*,
which is satisfied by a machine that is about to lose the plugin.

Two properties of claude.ai make the wrong reading easy, both measured:

- The organisation's admin surface and the account's are different scopes. A marketplace
  added to the first applies to everyone in the organisation; `"scope": "account"` comes
  from the second, under Customize → Plugins.
- The curated list under *Browse Anthropic sources* holds six vertical marketplaces and
  **not** `claude-plugins-official`. Anthropic's own plugin marketplace is reachable only
  through *Add marketplace*, which takes a GitHub `owner/repo` or a Git URL — the same
  door `skills-leadership` went through.

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

`skills-leadership` has since been taken off the account and moved to project scope, and the paragraph above stays where it is: what it measured — the account can carry a private GitHub repository — is still true, and the boundary below rests on it. What changed is a fact about the world, not this decision. It does move `leadership-toolkit` onto the one row this ADR already warns about, because `~/Development/21st-brain` is not a clone; making it one, with both keys checked in, is what would carry it.

That fixes the boundary of this decision more precisely than "private or public": the account path is a **GitHub** path. A marketplace on a private host that is not GitHub has no demonstrated route onto the account, and would be the next candidate for a named exception. There is none today.

So this repository declares nothing on the agent-tooling surface, without qualification, and `extraKnownMarketplaces` leaves the managed `settings.json` with no entry held back.

`chezmoi apply` strips `enabledPlugins` from the managed `~/.claude/settings.json`, because Claude Code writes that key into a file this repository hand-authors. That is the intended behaviour and not a defect to be engineered around: the key is the local truth this decision refuses to keep, and losing it on every apply is what pushes the act back onto the account. A `modify_` script that preserved foreign keys would be machinery built to defeat the decision. `autoMode.environment`, written into the same file, is derived from whatever project was last worked in and may die with it.

Two measurements from the second rebuild, recorded because the obvious checks mislead. `anthropics/claude-plugins-official` took well over ten minutes to finish registering — most of the thirteen minutes noted above was the marketplace, not the plugin — so a first quarter hour that shows nothing is still not evidence. And on the Mac Studio, `~/.claude/plugins/synced/*/.marketplaces.json` lists only the organisation's library: the account marketplace does not appear there although its plugin arrived and loads. The presence of the plugin in the bucket is the evidence that the path works. That file is not.

## Amendment: there is now a `modify_` script, and it is the one this decision asked for

The Consequences above say that a `modify_` script "that preserved foreign keys would be machinery built to defeat the decision". That sentence still holds exactly as written, and `home/dot_claude/modify_settings.json.tmpl` now exists without contradicting it.

The script emits the declared keys and **only** the declared keys, reordered to match the machine's copy. So `enabledPlugins`, `autoMode.environment` and anything else Claude Code writes into the file are still stripped by `chezmoi apply`, and still reported by `drift` before they are. Nothing is preserved; nothing this decision refuses to keep is kept.

What it removes is the key *reordering*, which changes no value and which made `chezmoi status` report the file forever — a finding always present and never meaningful. The distinction is the whole point: preserving a foreign key would hide a decision owed to the repository, and reordering the declared ones hides nothing.

The reasoning is ADR 0006's, amended; this note exists so that a reader who arrives here — at the decision that owns this file's foreign keys — is not left with the older answer.
