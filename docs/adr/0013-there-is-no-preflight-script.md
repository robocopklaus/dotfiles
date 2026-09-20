# There is no preflight script; the gate is the only entry point

The preflight is the set of preconditions a rebuild needs before it can write anything. The tempting shape is a second script — one `curl`-piped command that either performs the preflight or checks it, run before the bootstrap. There is none, and there will not be one.

**A script that *performs* the preflight is a second entry point.** It would be fetched and trusted before anything exists to check it, and it would be the least-tested script in the repository: CI's runner arrives warm, with Homebrew present and the Command Line Tools installed, so it never exercises bare metal. It would also have to run before the Command Line Tools are verified, since nothing has checked anything yet — and Homebrew wants them. The gate has that order for free: it verifies the foundation, then installs on top of it (ADR 0012).

**A script that *checks* the preflight is worse.** It is a second copy of the gate's list, which is *one list, one truth* failing in the one place it is most dangerous — the copy that drifts is the copy that waves a broken machine through.

**What no script of either kind can do is the GUI work**, and that is the slow part: the Apple Account, the 1Password sign-in and its two developer toggles, the GitHub key registration. A preflight script would automate the fast half and leave the slow half exactly where it was.

## Considered options

**A `preflight.sh` that installs and configures what it can.** The part of this worth having came true inside the gate instead (ADR 0012): Homebrew and the two 1Password casks are acquired by the run, after the foundation is verified and while root is already held. Nothing is left for a separate script except the GUI work it could not do anyway.

**A `preflight.sh` that only checks, and prints what is missing.** Rejected as a second list. The gate already prints every failed item with the remedy that fixes it, before a single file is written, which is the same output one step later and with no second copy to maintain.

**A checklist in documentation, checked by a human.** Such a table once existed here, and it said so itself: the gate is normative, the table is a human summary, and if they disagree the gate is right. A summary that is never authoritative is a list waiting to drift.

## Consequences

**A fresh machine stops at the gate exactly once**, and learns everything it is missing from the thing that enforces it. There is nowhere else to look.

**The remedies live in the gate script, beside the checks they serve** — never as a second column in a table somewhere else. A list of fix commands maintained apart from the checks it serves would drift from them.

**The bootstrap command is the only entry point in the repository.** There is no `install.sh`, no prologue and no preflight script (ADR 0001).
