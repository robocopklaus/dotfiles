# A chezmoi-driven, convergent bootstrap

The rebuild runs as a single command that installs chezmoi and applies this repository. chezmoi orchestrates every phase itself; there is no wrapper script, no recorded progress state, and no step that waits for a human mid-run.

## Considered options

**A prologue script that installs prerequisites, then hands off to chezmoi.** Rejected. Cloning the source needs `git`, `git` needs Xcode Command Line Tools, and CLT is one of the slowest things to install on a fresh machine. chezmoi's `--use-builtin-git=true` unties that knot by cloning without system `git`, and `get.chezmoi.io` installs the binary. A local `install.sh` would re-implement both, worse, and would reintroduce the dependency it exists to avoid.

**Checkpoint-and-resume for recovery.** Rejected. A progress file is itself state that can be wrong, and a stale checkpoint silently skipping a phase fails far more confusingly than re-running does. `run_onchange_` already skips unchanged work by content hash, so most of the speed argument is already paid.

## Consequences

Every phase must be safe to run any number of times. `run_once_` scripts are therefore banned outright: re-running the command is the only recovery mechanism, so a phase that cannot be made idempotent is a bug to be fixed rather than something to route around.

Phases are cut by **precondition**, and a numeric filename prefix records an order that a stated precondition justifies — the prefix is never itself the justification.

Because nothing pauses, every manual step becomes a precondition check with an actionable message rather than an interactive prompt. The run either completes or stops and tells you what to do before running it again. This is what moves Xcode Command Line Tools out of the run and in front of it: waiting up to an hour for an installer mid-run contradicts an unattended bootstrap, and unlike the 1Password CLI — which cannot exist before packages are installed — CLT can be satisfied beforehand.

A phase aborts the run only if a later phase depends on it. Optional leaves such as GUI casks and Mac App Store apps are installed individually, and their failures are collected and reported rather than killing a fresh bootstrap.
