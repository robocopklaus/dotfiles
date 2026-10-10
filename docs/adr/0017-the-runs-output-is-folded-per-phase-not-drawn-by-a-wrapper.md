# The run's output is folded per phase, not drawn by a wrapper

The run prints what it did and folds away how it did it. Each phase draws a header, then one line per thing it did — a gate check, a cask, an App Store entry, a defaults write, the Dock — with a spinner that resolves to ✓ or ✗. A step's output is captured while it runs and shown only if it fails: the last 20 lines, and a pointer to `chezmoi apply --verbose` for the whole of it. What is skipped prints nothing, as before.

Every phase draws itself, through one library included at render time, `lib/ui.sh`. There is no wrapper around the run and no full-screen view.

**A wrapper would have nothing to wrap on the run that matters most.** chezmoi runs each phase as its own process, so nothing inside the run lives long enough to own the terminal; only a program around `chezmoi apply` could. That program would be a second entry point, which ADR 0001 and ADR 0013 rule out, and it would not exist on the first bootstrap — the `curl | sh` run, onto a machine with nothing on it, which is the run this repository exists to serve. A progress view that is absent on a rebuild misses its own point.

**No dependency draws it.** The gate includes the library before Homebrew exists, so a drawing tool such as `gum` would have to be acquired before the gate, joining a trust chain that is deliberately Homebrew and the two 1Password casks (ADR 0012). Plain bash and ANSI escapes are enough for one reader at one terminal.

**The detail is ephemeral.** A step's output goes to a temporary file that is deleted when the step ends. A log kept per phase was the alternative, and it would go stale by construction: a `run_onchange_` phase that is skipped leaves the previous run's log behind, looking current. That is recorded state, which the convergence invariant bans. `--verbose` re-runs and shows everything; nothing needs to be kept.

**The switch is the machine's.** Whether stdout is a terminal decides whether anything is folded or coloured. CI and redirected output get the tools' own output, unfolded and escape-free, as before. `chezmoi apply --verbose` sets `CHEZMOI_VERBOSE` in every script, and that unfolds a terminal run too. There is no flag of this repository's own, no `NO_COLOR` and no width detection.

## Considered options

**A wrapper script that runs `chezmoi apply` and draws the whole run.** Rejected as above: a second entry point that the first bootstrap would not have.

**`gum` or a similar tool.** Rejected: it would have to be installed before the gate that acquires everything else.

**A log file per phase, kept after the run.** Rejected: a skipped phase leaves a stale log that reads as current.

**Folding the gate's checks behind spinners.** Rejected for the checks, which take milliseconds and are printed as plain ✓/✗ lines with the remedy beneath a failure. `sudo -v` is never folded, so its password prompt stays visible.

## Consequences

**A folded step reads from `/dev/null`.** A command that wanted input fails and unfolds, rather than waiting silently behind a spinner. `sudo` is the exception, because it reads its password from the terminal itself rather than from stdin. It is held off by the keepalive, which keeps the timestamp warm for the whole phase, and not by the redirect.

**A step runs where `set -e` does not reach.** Bash suspends it for any command whose status is tested, so a step that is a shell function returns its own failures explicitly.

**CI never takes the folded path**, because the runner has no terminal. `tests/ui.sh` drives the library under a pseudo-terminal so that it is exercised at all.

**chezmoi's own verbose output is accepted.** Under `--verbose` it also prints each script it runs, the Packages phase's inlined Brewfile included.
