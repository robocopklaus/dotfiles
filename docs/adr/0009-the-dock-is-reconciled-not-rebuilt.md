# The Dock is reconciled, not rebuilt

The Dock's layout is managed. It is declared as **ordered categories of applications** in `home/.chezmoidata/dock.toml`, and `run_onchange_after_61-dock.sh.tmpl` brings the machine to that declaration in P6, after the applications exist.

The script **reconciles**: it reads the Dock's current tile sequence, compares it to the expected one, and rebuilds through `dockutil` only when they differ. On a converged machine it is a silent no-op — no clear, no rebuild, no `killall`. The expected sequence is the declaration **rendered**: apps that are not installed drop out, and a small spacer is emitted after each category that still has a member.

The declaration is a list of application names per category, not a literal tile sequence. Spacers are generated between categories rather than declared, so a category emptied by a future content review leaves no stray separator behind. The two folders — `/Applications` (auto, sorted by name) and `~/Downloads` (auto, sorted by date added) — close the sequence and carry their display options with them.

A Dock entry is a **reference** to an application the repository already declares, never a second declaration of it. CI enforces the direction: every name in `dock.toml` must resolve to a Brewfile entry or to an Apple system application, and the build fails otherwise.

The drift report gains one line under **Diverged value** — the layout matches or it does not — followed by the expected and actual tile sequences. The comparison is the same one the reconcile performs, so the check and the application are one mechanism.

## Considered options

**Unconditional clear-and-rebuild, as the prior setup did.** Rejected, and the case for it was weaker than it looked. It converges in effect, but it deletes any tile added by hand and restarts the Dock on every unrelated `chezmoi apply` — a visible flash as the price of a step that usually changes nothing. It also stands against the convergence invariant in ADR 0001 in the way that matters: re-running the command is supposed to be the recovery, not a thing you learn to avoid.

**Applying the layout only on a fresh machine.** Rejected outright: ADR 0001 forbids `run_once_`, and a layout that is applied once is a layout that silently rots.

**Declaring the literal tile sequence, spacers included.** Rejected. The category grouping is what the annual review actually reasons about — whether an application still belongs under Communication — and a flat sequence turns the six spacers into editable noise that has to be kept consistent by hand.

**Deriving the Dock from the Brewfile.** Rejected because the Brewfile cannot express it: it has no order, no categories, and holds 38 entries against the Dock's 14. The Dock is a chosen subset in a chosen order, which is information the package list does not carry.

**A `[dock]` table inside `macos-defaults.toml`.** Rejected. The two share the `com.apple.dock` domain but not their shape: the defaults table is flat `domain/key/type/value` rows, and ADR 0002 depends on that flatness. Nesting an ordered structure inside it would spend the uniformity that #11 bought by cutting its last `PlistBuddy` key. Two files, two shapes, one directory.

**Enumerating the drift per tile, or splitting it across the report's three sections.** Rejected. The split scatters a single fact — the layout diverged — under three headings, and the *Missing* case is not the Dock's to report: an application absent from the Dock because it was never installed is a package failure the Brewfile sweep already owns. Printing both sequences gives the same information as a per-tile diff for a fraction of the shell.

**Comparing against the raw declaration rather than the rendered one.** Rejected. A single missing cask would then be reported twice — truthfully by the Brewfile section, misleadingly as layout drift — and the Dock section would be red on every machine until the bootstrap finished.

## Consequences

The plist backup and its five-deep prune are deleted. They insured against a destructive rebuild, and a rebuild that fires only on genuine mismatch has nothing left to insure. #11 deleted the equivalent backup dance for defaults on the same reasoning.

The `com.apple.dock` domain has two managers: the flat defaults table and this layout. That is accepted, because the layout genuinely cannot be expressed as `domain/key/type/value`. Two *restarts* are not accepted: the layout step reports its change into the same restart rule #11 defined, and one `killall Dock` at the end of the run covers both.

A Dock that is short a tile because its application never installed reports **clean** here and **red** in the Brewfile section. This is the intended split of ownership, and it means the Dock section alone is not a statement about completeness.

`zen` is removed from the Dock. The content review cut it as the clearest cut in its list, while the prior Dock declaration still placed it fifth — the exact two-lists-one-truth drift this repository rejects, and the reason the CI cross-check exists rather than being left to care.

The measurement that decided the application model: after four months the live Dock still matched the prior declaration exactly — 23 tiles, six spacers, both folders, same order. The objection that a managed Dock fights a Dock you have since rearranged has no evidence behind it on this machine, which is what makes a no-op reconcile the common case rather than an optimistic one.
