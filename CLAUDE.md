## Language

**Everything in this repository is written in English.** No exceptions: source code, identifiers, comments, documentation, commit messages, PR titles and descriptions, issue text, ADRs.

## Simplicity — YAGNI

The measure is cognitive load: how much must a reader hold in their head at once to change this safely? LOC, file count and concept count are coarse proxies, never the target.

- **Generality arrives with the second real consumer**, never speculatively — name the second call site, or the layer does not go in.
- **Deleting code is a win, and deletions must be behaviour-preserving** — never boundary validation, never error or empty states, never tests. Dead code found outside the work at hand is reported, not swept.
- **Split on a real seam, not on length; merge when reading one half always requires the other open.**

## Standing rules

These apply everywhere and are the ones most likely to be violated by accident.

- **One list, one truth.** Never two declarations of the same fact. Every "second list" proposal in this repository's history has been rejected on this ground, and every one that slipped through has drifted (`zen` cut from the inventory but still fifth in the Dock; Keynote cut but still installed).
- **`brew bundle dump` is never run against this repository.** It reads installed state and truncates the target file wholesale — there is no merge path — so it would erase every reason comment in the `Brewfile`. The inventory is hand-written.
- **Nothing stores a "last confirmed" date.** Staleness is re-derived from the machine at review time — see `docs/annual-review.md`. A field nobody updates does not degrade to "no information"; it degrades to a confident lie.
- **Guards derive from the machine, not from a flag** — whether `op` is on the path, not an environment variable someone sets. A flag is a second truth that can be set wrongly. The one exception is `CI`, which the runner sets and this repository never writes, so it is environmental fact rather than configuration.

## Agent skills

### Issue tracker

Issues live in GitHub Issues at `robocopklaus/dotfiles`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, using their default label strings. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
