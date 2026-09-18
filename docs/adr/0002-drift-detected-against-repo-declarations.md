# Drift is detected against the repository's own declarations

One command reports how the machine differs from this repository. It never enumerates the machine's full state; it enumerates what the repository declares and checks the machine against that, plus the few inventories that can be swept for entries the repository has never heard of.

The report has three sections, printed in this order, with empty sections omitted:

- **Missing on the machine** — the repository declares it, the machine lacks it. A convergence failure; the fix is to run the bootstrap again.
- **Not in the repository** — the machine has a formula, cask, App Store app or dragged-in `/Applications` bundle that nothing declares. A decision owed to the repository, not a failure.
- **Diverged value** — a managed file or a managed default whose value no longer matches.

The command only reports. It exits 0 when clean and 1 on any drift.

## Considered options

**Rely on chezmoi alone.** Rejected, after measuring it. `chezmoi status` and `chezmoi verify` cover managed files completely, and are used as-is for that section. But a `run_onchange_` script is tracked by the hash of its *content*, not by its *effect*: changing a setting in System Settings after the script applied it leaves `chezmoi status` clean. Defaults drift is therefore invisible to chezmoi by construction, and that is precisely the drift worth catching. Packages are likewise outside its model, but `brew bundle cleanup --dry-run` and `brew bundle check` already answer them.

**Enumerate the machine's defaults.** Rejected. A Mac holds thousands of defaults and perhaps a dozen are meaningful. Enumerating the repository's declarations instead bounds the comparison set to a number that is chosen rather than discovered — a noisy key is then a key that should not be managed, which is a question with an owner.

**Parse the `defaults write` lines out of the apply script.** Rejected. It is a parser for a Turing-complete language that breaks at the first conditional.

**Keep a second list of expected values beside the script that writes them.** Rejected. Two lists and one truth guarantee drift — an unusually poor property for a drift detector.

**A `--json` output, and an `--adopt` flag that writes findings back.** Rejected for now; neither has a second consumer. Adoption in particular cannot be mechanical, because every managed entry must carry a stated reason and only a human can write one.

**A scheduled run, by launchd or on shell login.** Rejected. A recurring prompt on a machine that is reviewed once a year trains you to dismiss it, and a report nobody reads is worse than no report because it looks like coverage.

## Consequences

Managed macOS defaults are declared as **data** — domain, key, type and expected value — and both the applying script and the check are derived from that one declaration. This is what makes the defaults section possible at all, so it is a constraint on how defaults are managed rather than a preference about file formats.

Homebrew formulae are swept as **leaves** only. Dependencies are not decisions, and listing them would bury the entries that are.

Apps in `/Applications` that came from neither Homebrew nor the App Store are swept too. A dragged-in app is the one class of drift the Brewfile structurally cannot catch, and the class most likely to survive a wipe by being forgotten.

The same command runs unprompted only at the end of a bootstrap. No separate brief mode is needed: on a fresh machine the *not in the repository* section is empty and therefore not printed.

The name `doctor` is avoided, because `chezmoi doctor` already exists and answers an unrelated question — whether chezmoi itself can operate here.
