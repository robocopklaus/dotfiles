## Language

**Everything in this repository is written in English.** No exceptions: source code, identifiers, comments, documentation, commit messages, PR titles and descriptions, issue text, ADRs.

## Simplicity — YAGNI

The measure is cognitive load: how much must a reader hold in their head at once to change this safely? LOC, file count and concept count are coarse proxies, never the target.

- **Generality arrives with the second real consumer**, never speculatively — name the second call site, or the layer does not go in.
- **Deleting code is a win, and deletions must be behaviour-preserving** — never boundary validation, never error or empty states, never tests. Dead code found outside the work at hand is reported, not swept.
- **Split on a real seam, not on length; merge when reading one half always requires the other open.**

## Agent skills

### Issue tracker

Issues live in GitHub Issues at `robocopklaus/dotfiles`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, using their default label strings. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
