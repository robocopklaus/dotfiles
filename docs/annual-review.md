# The annual review

The review happens **at the desk, before the wipe** — that is the entire point. The wipe
is a forced review date, and the bootstrap that follows it is pure execution: no
decisions, no rediscovery, nothing pulled back over the following weeks because it was
missed.

It is run against the repository's declarations: the `Brewfile`, `Brewfile.work`,
`home/.chezmoidata/`, and the managed configuration under `home/`.

This document is read on a machine that is about to be erased, and sometimes on one that
has just been. It lives in the repository rather than in the issue tracker for that
reason.

## The steps

1. **Run `drift`.** Its second section, *Not in the repository*, is the year's agenda:
   everything the machine acquired that nothing declares. Each entry is a decision owed —
   adopt it with a reason, or let the wipe take it.

2. **Re-derive usage from the machine, not from the file.** Nothing in this repository
   stores a "last confirmed" date; a field nobody updates does not degrade to "no
   information", it degrades to a confident lie. Read staleness off the live machine
   instead:

   ```sh
   brew leaves                                  # formulae that are decisions, not dependencies
   brew list --cask
   mas list
   mdls -name kMDItemLastUsedDate /Applications/<App>.app
   ```

   plus shell history for the CLI entries.

   This is exactly how the inventory was judged the first time, and it is deliberately
   **not** a command in this repository: it has one consumer, once a year, and its output
   is a reading rather than a pass/fail. Building a tool for it would be speculative
   generality — and folding it into `drift` would break that command's exit-code contract,
   which CI depends on as an oracle.

3. **Apply the bar.** See below.

4. **Re-ask the one open sourcing question.** Has a Homebrew cask appeared for any of the
   four App Store entries (ADR 0007)? That is the only per-app question the review ever
   asks about sourcing.

5. **Check the upstream health of the load-bearing tools** — chezmoi and mise above all.
   Two things are on watch: `mise` has grown its own dotfiles feature, which would collapse
   two tools into one if it matures, and chezmoi's bus factor is real but unquantified.

6. **Curate the claude.ai account.** It is the restore mechanism for the entire
   agent-tooling surface (ADR 0010), and this repository checks nothing about it. A plugin
   whose marketplace is registered nowhere but on this machine does not survive a wipe,
   silently — the same failure this repository exists to end, moved one level up. Enabling
   is not registering: read the account's marketplaces, not the machine's enabled plugins.

7. **Then wipe**, and run the bootstrap command.

## The bar

**Demonstrated use.** If an entry leaves no trace between two reviews it goes; "cheap to
reinstall on demand" is the standing answer to "but what if". There is no second, softer
threshold for barely-used tools — "it left a trace" is checkable next January, "it didn't
feel like enough" is not.

Two exceptions, both written into the entry's own reason so the exemption is not
re-litigated:

- **Bootstrap dependencies** are kept because a script invokes them, never because they
  are typed.
- **Background applications** — a URL handler, a sync daemon, a browser extension — have
  no launch record by design, so absence of one cuts nothing.
