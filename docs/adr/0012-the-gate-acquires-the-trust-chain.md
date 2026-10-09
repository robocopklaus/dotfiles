# The gate acquires the trust chain before it verifies it

The gate checks the preconditions of the run. It now also installs two of them — Homebrew, and through it the `1password` and `1password-cli` casks — before the checks that ask for them run. A checker that installs software is surprising enough to write down.

**The reason is that they were never a decision.** Everything else in the preflight is either a judgement (which machine, which network) or a sign-in no script can perform (the Apple Account, the 1Password unlock, the two developer toggles, the GitHub key registration). The trust chain was neither. It was three commands, in a fixed order, that a human had to type correctly before the run would proceed — and this repository exists to end exactly that kind of rediscovery. The gate holds root, has just verified the Command Line Tools and the network, and is the last thing to run before files are written. It is the only place in the run that can do it.

**The checks did not change, and that is what makes it safe.** The gate installs, then asks the same questions it always asked: is the app in `/Applications`, is `op` on `PATH`. A failed acquisition refuses with the same remedy naming the same command, so the path that used to be the only path is still there, still tested by being the fallback. Nothing was traded for the convenience except the order things happen in.

**It does not make the run unattended, and no version of it could.** P3 renders the work identity through `op`, which needs a signed-in, unlocked, CLI-integrated 1Password. A fresh machine stops at the gate once, whatever the gate installs. The acquisition shortens what the human does at that stop; it does not remove the stop.

## Considered options

**Leave it to the human, with a better remedy.** This was the previous decision, and it is what this one replaces. The remedy named Homebrew and the `brew` command, which was already an improvement on pointing at a vendor page that offers a `.pkg` — but it still asked for commands rather than issuing them, and it still left the person to notice that a freshly installed Homebrew is not yet on `PATH`.

**A phase of its own, before the gate.** Rejected on cost, not on principle. Phases are cut by precondition, and "Homebrew plus the trust chain" has a real one — root, network, Command Line Tools. But inserting it means either renumbering every phase, script filename and cross-reference, or inventing a label that weakens the rule that a phase number records a justified order. The gate already holds the privilege and has already checked the foundation; a second phase would re-acquire both to earn a number.

**A preflight script that performs P0.** Rejected before and still rejected: a second entry point, fetched and trusted before anything exists to check it, and the least-tested script in the repository. The part of it that was worth having is the part the gate now does, from inside the run, after the foundation is verified.

## Consequences

**The gate stops in two places rather than one.** The foundation — root, architecture, macOS version, network, Command Line Tools — is reported in one pass and refuses there, because the acquisition stands on all five. Only then are the trust-chain items checkable. A machine missing both the Command Line Tools and the 1Password sign-in learns about them in two rounds. The one-pass promise now holds within a stop, not across the run.

**A refusal no longer leaves the machine untouched.** `$HOME` is still untouched, which is what P3 depends on. But `/opt/homebrew` and `/Applications` may have gained contents before the gate refused on a toggle. The gate prints what it installs as it installs it, so the change is visible rather than merely true.

**CI skips the casks.** The runner arrives with Homebrew and wants neither 1Password, and its 1Password checks already report rather than refuse. So the acquisition is exercised on bare metal only — the same blind spot CI already records for everything bound to a fresh machine.

## Amendment: the privilege is acquired for installing, so a run that installs nothing does not ask

`run_before_20-gate.sh` is a `run_before_` script, and `run_before_` is a hook on *apply*. An update is an apply, so once `chezmoi update` became the documented everyday verb the gate moved in front of it too — asking for an administrator password to pull in a documentation commit. Nobody decided that; the mechanism decided it, because apply is the one verb a rebuild and an update share.

The measurement that settles it: **nothing in this repository ever runs a command as root.** The only `sudo` in the tree is `sudo -v` in this gate and `sudo -n true` in `lib/keepalive.sh`. No phase is prefixed with it. `run_after_42-claude-code.sh` refuses it outright, `41-mas` states that `mas install` must not carry it, and P6's `defaults write` and `dockutil` are user-scope throughout. The privilege has exactly one consumer: Homebrew's own cask installers, which ask macOS for root themselves when a cask ships a `pkg`.

So the question in front of the acquisition is not *which verb was typed* and not *is this a rebuild*. It is **will this run install anything** — and that is asked of the machine.

### Why not a record of when the gate last ran

The tempting cheap version is a stored "the gate passed recently" marker, and it is the dangerous one. A field nobody updates does not degrade to no information, it degrades to a confident lie, and this repository bans recorded intermediate state under convergence for that reason. Nothing here stores anything: the answer is recomputed from the machine on every single run, and a machine that has drifted back to missing software is asked for the password again, correctly.

### What asks, and what it asks with

The gate inlines the inventory at render time — the same `include` the P4 scripts and `drift` use, so this is one list read a fourth time and not a fourth list — and puts it to `brew bundle check`. Homebrew's own answer to "is everything in this Brewfile installed", rather than a second implementation of `drift`'s sweep sitting inside a gate. No Homebrew at all is the fresh machine and the answer is yes without asking further, which is what a rebuild needs and is why this cannot wave one through.

A reader who finds `brew bundle check` inside a *gate* will reasonably wonder what it is doing there. It is standing in for the sentence above: the privilege exists for installers, so the gate asks whether there will be any.

### What did not become conditional

Everything else. Architecture, macOS version, network reachability, the Xcode Command Line Tools, 1Password.app, `op` on `PATH`, `op account list`, the SSH agent socket: all of them run on every apply, unchanged. They are non-interactive and cost nothing, and the 1Password items in particular are not stale-proof the way the architecture is — the SSH agent toggle can genuinely be off on a Friday when it was on on Tuesday, and P3's templates read through it on every apply. Pruning them would have been optimising the free half of the complaint. Exactly one thing is conditional, which is what makes this explainable.

The ordering invariant this decision rests on is also unchanged: the acquisition still happens in the gate, before a single file is written, so no later phase discovers a missing privilege halfway through a bundle. Acquiring lazily inside the install phases would have been tidier to write and would have broken that, moving the run's one interactive moment into its middle.

### The phases follow the gate, they do not re-decide it

P4 starts a keepalive of its own, because each chezmoi script is a separate process and a warm loop cannot be adopted across one. That keepalive opens with `sudo -v`, so left unconditional it would undo this decision from the other end. The two questions are not the same question: the gate asks whether anything is *missing*, while `run_onchange_` re-triggers on whether the inventory *changed* — and an edit that installs nothing, a reason comment or a removed entry, separates them. The gate would then correctly acquire no privilege and P4 would ask for a password in the middle of the run, which is precisely the failure the ordering above exists to prevent.

So 40 and 41 start their keepalive only where the privilege is already warm, asked with `sudo -n true`. That is the gate's decision read back off the machine rather than derived a second time, and reading it is what keeps the two from disagreeing: asking the inventory question in three places would be three chances to answer it differently, and the copy that answers differently is the one that waves a run through. Where the gate acquired nothing, these phases have nothing to spend it on either — both install loops already skip what is present.

The residual case is a privilege that expires between the gate and P4. Those phases then install without a warm loop, and a long cask download can meet a prompt — which is the behaviour this repository had before the keepalive existed, so this decision does not make it worse. The alternative, reaching for root again on the strength of a guess, is the thing this amendment exists to stop.

### Consequences

`chezmoi update` becomes available to a shell with no controlling terminal, on any run that installs nothing — which is most of them. It is not unconditionally available, and that is deliberate rather than a gap: an update that pulls a `Brewfile` change genuinely does install software, and installing software needs a human. The refusal says so in those words and names the installs, instead of reporting a failed precondition; the remedy is to run it again in a terminal window. Refusing whole is the alternative to a partial apply that leaves the machine in a state no verb produced.

The gate gains a dependency on Homebrew being on `PATH` before it can ask its question. The foundation section two checks earlier already establishes the machine it runs on, and the prefix cascade is included ahead of the question, so a machine without Homebrew answers "yes, installs are pending" rather than failing to answer.

The everyday run no longer starts its keepalive loop or its `sudo -v`, so the two seconds and the password prompt both go. That is the whole user-visible change, and it is the one the issue asked for.
