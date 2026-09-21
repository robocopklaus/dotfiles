# The rebuilt Mac

This repository is the source two identical Apple Silicon Macs are rebuilt from, wiped
and reinstalled at least once a year. This file is the glossary and nothing else: the
words that carry a specific meaning here. What the repository manages is declared by the
repository itself — the `Brewfile`, `home/.chezmoidata/`, and the managed files under
`home/`. The structural decisions are recorded as ADRs under [docs/adr/](docs/adr/).

## The run

**Rebuild**:
A wipe of a machine followed by one bootstrap. The unit of work this repository exists to
serve, performed at least once a year.
_Avoid_: setup, provisioning, reinstall

**Wipe**:
The erase-and-reinstall of macOS that opens a rebuild. It is a forced review date — the
deadline that makes the annual review happen at all.

**Bootstrap**:
The single command that carries a freshly installed machine to a working one, and the only
recovery mechanism there is. Re-running it is always safe.
_Avoid_: install, install script, provisioning run

**Phase**:
One step of the bootstrap, cut by a precondition and never by numeric convention. Its
number records an order that a precondition justifies; the number is never itself the
justification.
_Avoid_: stage, step

**Preflight**:
The preconditions of the run. Most are work done by hand on the fresh machine before the
command is typed; the ones a command can satisfy are acquired by the gate instead. The
gate, not any summary of it, is the normative statement of what it contains.
_Avoid_: manual steps — not all of them are

**Gate**:
The phase that acquires what a preflight item can be acquired by — privilege, and the
trust chain — and verifies every one of them, before a single file is written. It stops
at the foundation first, because that is what the acquisition stands on.

**Epilogue**:
The closing report at the run's tail. It re-derives what is missing by checking the world;
it never replays what earlier phases recorded.
_Avoid_: summary, final report

**Trust chain**:
Homebrew and the two 1Password casks: what everything else in the run is fetched and
signed through. Acquired by the gate rather than asked of a human, because it is the only
part of the preflight that is a command rather than a decision or a sign-in.

**Convergence**:
The property that repeated runs reach the same state. It bans recorded intermediate state:
no checkpoint file, no scratch file a phase appends to, nothing that can go stale and then
lie.

**Remedy**:
The command or click path the gate prints beside a failed precondition. It lives in the
gate script next to the check it serves, never in a list maintained apart from it, and it
names one way — a remedy that offers a choice has handed the decision back.

**Refuse**:
To stop before changing anything, with a precise instruction. What the gate does to a
failed precondition, and what `~/.gitconfig` does to a commit no identity matches.

**Abort**:
To stop the run because a later phase depends on what just failed.

**Degrade**:
To report a failure and carry on, because nothing later depends on it. A tolerant phase
must have tolerant dependents.

## What the repository manages

**Declaration**:
A statement in this repository of a fact about the machine. Every fact has exactly one —
a second declaration of the same fact is the defect the standing rules exist to prevent.
_Avoid_: config, definition, spec

**Managed**:
Declared by this repository, and therefore restored by a rebuild and checked by drift.
Everything else on the machine is a decision that has not been made yet.

**CLI integration**:
The 1Password setting that hands the account to `op`. Without it `op` holds no account at
all, and asks for one — which is why it is a gate item rather than something P3 discovers.

**App data access**:
Whether the process that starts the run may read the 1Password app's own data. The CLI
integration can be on and the handover still fail on it, which is why the gate asks it
before naming a remedy.
_Avoid_: permission, Full Disk Access, TCC

**Vault state**:
What a 1Password item holds that no template reads. A rebuild does not restore it and
drift cannot see it, so it is never where a fact about the machine lives. The item hands
over field values; this repository owns the structure built from them.
_Avoid_: 1Password setting, app state

**Inventory**:
The Brewfile: the full truth of the applications and tools on the machine. It is
hand-written, never dumped from installed state.
_Avoid_: package list, manifest

**Unmanaged tail**:
The installed things nothing declares. Rejected by design — an unmanaged tail means the
wipe still silently deletes things, which is the loop this repository ends.

**Out-of-band installer**:
An entry the inventory names but neither Homebrew nor the App Store can carry, installed
by its own vendor script.

**Account marketplace**:
A plugin source registered on the claude.ai account, rather than known only to one
machine. It is what carries agent tooling across a wipe, and registering it is a separate
act from enabling a plugin from it — the mistake ADR 0010 was written before, and
amended after. This repository declares none of them; the word exists so the decision can
say which act it means.
_Avoid_: enabled plugin, installed plugin

**Managed default**:
A macOS setting declared as data — domain, key, type, value — rather than as a command.

**Reason**:
The comment on a managed entry stating why it is here. It is what makes the annual review
a decision rather than an archaeology exercise, so an entry without one is incomplete.

**Drift**:
The disagreement between a machine and this repository — something missing, something
undeclared, or a managed value diverged. Never measured between two machines: the
repository is the shared reference. Also the name of the command that reports it.
_Avoid_: doctor, diff, divergence

## Identities

**Identity**:
The bundle a commit is made under: a name, an address, a signing key, and the account that
verifies it. Two identities may share one key while keeping separate addresses — the key
belongs to the account, the address belongs to the engagement.
_Avoid_: profile, persona, account

**Personal identity**:
The identity for this person's own work. Public on GitHub, and therefore kept in cleartext
in this repository.

**Company identity**:
The identity for 21st digital's work on github.com. Shares the personal identity's account
and key; only the address differs.

**Work identity**:
The client-issued identity, whose account and hosts belong to a client. The word *work* is
a deliberately neutral cover: what this repository keeps out of a public tree is the client
relationship, so filenames, the 1Password item and its vault must never name the client.
_Avoid_: client identity, employer identity

**Work group**:
The client-facing entries of the inventory, carried in a separate file under the same
condition as the work identity. One client relationship, one condition, so the two can
never disagree.

## Reasoning

**The map**:
The GitHub issue and its tickets where the reasoning behind the rules lives. The
repository states the rule; the map is why it is the rule.
