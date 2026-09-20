# The gate acquires the trust chain before it verifies it

The gate checks the preconditions of the run. It now also installs two of them — Homebrew, and through it the `1password` and `1password-cli` casks — before the checks that ask for them run. A checker that installs software is surprising enough to write down.

**The reason is that they were never a decision.** Everything else in the preflight is either a judgement (which machine, which network) or a sign-in no script can perform (the Apple Account, the 1Password unlock, the two developer toggles, the GitHub key registration). The trust chain was neither. It was three commands, in a fixed order, that a human had to type correctly before the run would proceed — and this repository exists to end exactly that kind of rediscovery. The gate holds root, has just verified the Command Line Tools and the network, and is the last thing to run before files are written. It is the only place in the run that can do it.

**The checks did not change, and that is what makes it safe.** The gate installs, then asks the same questions it always asked: is the app in `/Applications`, is `op` on `PATH`. A failed acquisition refuses with the same remedy naming the same command, so the path that used to be the only path is still there, still tested by being the fallback. Nothing was traded for the convenience except the order things happen in.

**It does not make the run unattended, and no version of it could.** P3 renders the work identity through `op`, which needs a signed-in, unlocked, CLI-integrated 1Password. A fresh machine stops at the gate once, whatever the gate installs. The acquisition shortens what the human does at that stop; it does not remove the stop.

## Considered options

**Leave it to the human, with a better remedy.** This was the previous decision, and it is what this one replaces. The remedy named Homebrew and the `brew` command, which was already an improvement on pointing at a vendor page that offers a `.pkg` — but it still asked for commands rather than issuing them, and it still left the person to notice that a freshly installed Homebrew is not yet on `PATH`.

**A phase of its own, before the gate.** Rejected on cost, not on principle. Phases are cut by precondition, and "Homebrew plus the trust chain" has a real one — root, network, Command Line Tools. But inserting it means either renumbering every phase, script filename and cross-reference in the specification, or inventing a label that weakens the rule that a phase number records a justified order. The gate already holds the privilege and has already checked the foundation; a second phase would re-acquire both to earn a number.

**A preflight script that performs P0.** Rejected in §2 and still rejected: a second entry point, fetched and trusted before anything exists to check it, and the least-tested script in the repository. The part of it that was worth having is the part the gate now does, from inside the run, after the foundation is verified.

## Consequences

**The gate stops in two places rather than one.** The foundation — root, architecture, macOS version, network, Command Line Tools — is reported in one pass and refuses there, because the acquisition stands on all five. Only then are the trust-chain items checkable. A machine missing both the Command Line Tools and the 1Password sign-in learns about them in two rounds. The one-pass promise now holds within a stop, not across the run.

**A refusal no longer leaves the machine untouched.** `$HOME` is still untouched, which is what P3 depends on. But `/opt/homebrew` and `/Applications` may have gained contents before the gate refused on a toggle. The gate prints what it installs as it installs it, so the change is visible rather than merely true.

**CI skips the casks.** The runner arrives with Homebrew and wants neither 1Password, and its 1Password checks already report rather than refuse (§8). So the acquisition is exercised on bare metal only — the same blind spot §8 already records for everything bound to a fresh machine.
