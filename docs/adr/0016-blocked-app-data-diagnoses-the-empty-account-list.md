# Blocked app data is a diagnosis of the empty account list, and its remedy is typed

`op` reads the account out of 1Password's own settings file, inside the app's group
container. macOS can refuse the terminal that read. When it does, `op` reports no account
with the CLI integration switched on, and ADR 0014's check — `op account list` — refuses
with a remedy naming the toggle, which is not the fault.

The gate therefore asks a second question *inside* that refusal, before it names a
remedy: is `$app_settings` present and unreadable? If it is, the remedy is to re-run the
command with `OP_BIOMETRIC_UNLOCK_ENABLED=true` in front of it, which makes `op` ask the
running app rather than read the file.

**Why inside and not beside.** This was first built as a check of its own, standing ahead
of ADR 0014's, and that was wrong in a way worth recording: the variable does not make
the file readable. It routes `op` around the file. A gate item conditioned on
unreadability therefore still holds on the machine its own remedy has just repaired — it
refuses a working machine, with an instruction already carried out, on every subsequent
run. The condition that clears is the one that was actually wrong: no account came back.
Unreadable app data is *why*, not *whether*.

The general shape: a precondition is what the run needs to be true. A diagnosis is what
distinguishes the ways it can be false. Only the first may hold the gate.

**Why the permission is not the remedy.** Granting the access would be the honest fix and
it is unreachable: macOS lists the terminal under none of Privacy & Security's panes —
not App Management, not Full Disk Access, not Files and Folders — so there is no switch
to turn on. Measured on a fresh Mac Studio, observed again in
[1Password/shell-plugins#587](https://github.com/1Password/shell-plugins/issues/587). This
is also why the item is not Full Disk Access under another name: the machine this
repository was written on reads the file without it.

**Why the remedy is typed rather than declared.** `op` is invoked in two places — this
check, and `onepasswordRead` in `lib/work-identity.json`. The second is rendered by
chezmoi *itself*, so the variable has to be in chezmoi's own environment. The gate is a
child process and cannot put it there, and `dot_zprofile.tmpl` is written in P3, after
the gate: on the run that needs it, the file does not exist yet. There is no arrangement
of this repository that sets the variable for the run that is failing. Naming it in a
remedy is not the lesser option; it is the only one.

**Why the refusal branches at all.** ADR 0014's check catches this machine already — the
account list is empty either way. What it cannot do on its own is tell the two apart, and
the two want opposite things done to them. A remedy listing both causes would hand the
reader the archaeology this repository exists to end.

**Why the file and not the error message.** `op --debug` names the cause in words
(`Skipped loading desktop app settings file … operation not permitted`). Those words are
1Password's to change, and a check that greps them passes silently the day they change.
The file is the fact; `-e` plus a one-byte read separates *refused* from *absent*, which
matters because the gate installs the app (ADR 0012) and an app never opened has written
no settings at all.

## Alternatives considered

**Leaving it to ADR 0014's check.** Rejected above: one check, two machines, and a remedy
that is wrong for one of them.

**Exporting the variable from `dot_zprofile.tmpl`.** Rejected. It cannot help the run
that needs it, and it would leave a permanent flag in the environment as payment for
that — a second truth about a machine, set for a failure that may already be gone.

**Naming the variable in the README's preconditions.** Rejected. It is the repair of a
defect, not a fact about the machine, and the README promises the reader does not have to
work the list out in advance.

**Waiting for the upstream fix.** Rejected as a plan, accepted as an outcome. The check
costs nothing on a machine where the file is readable: it does not fire, and the remedy
is never printed. Nothing here carries a date, in keeping with the standing rule — the
question a later reader asks is whether the check still fires, and the machine answers it.

## Consequences

The variable's name says biometric unlock and that is not what it is being used for here.
It changes which path `op` takes to the account, and the comment at the check says so,
because a reader who trusts the name will look for the wrong thing.

The gate can now stop twice over one machine: once refusing, and — for the reader who
fixes it the way the remedy says — not again. The run's promise is unchanged; it always
said it stops with a precise instruction and you run it again.

`agent-socket.sh` becomes `onepassword-paths.sh`, because two paths inside the group
container are now read and the container identifier is one fact.
