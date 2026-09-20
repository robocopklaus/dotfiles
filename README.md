# dotfiles

The source two Apple Silicon Macs are rebuilt from, in one command.

They are wiped and reinstalled at least once a year. The wipe is a forced review date,
so this repository has a second job and it is the harder one: every managed entry states
why it is here, so that standing in front of the list next January is a decision and not
an archaeology exercise.

It is built for two identical machines and one reader. Take it as a template, not as a
product — onboarding a third machine, or handing this to someone else, is not a goal.

## The command

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io/lb)" -- -- --use-builtin-git=true init --apply robocopklaus/dotfiles
```

That is the whole entry point. There is no `install.sh` and no preflight script: the
command installs chezmoi and clones this repository before Xcode Command Line Tools
exist, which is the knot a hand-rolled installer would have to untie again, worse.

Re-running it is the only recovery mechanism there is, and it is always safe.

## What the machine needs first

A freshly installed macOS with an Apple Account signed in, a network, and administrator
rights. Xcode Command Line Tools, via `xcode-select --install`. 1Password signed in and
unlocked, with both its SSH agent and its CLI integration switched on, and this machine's
public key registered on GitHub under *SSH keys* and *SSH signing keys* both.

You do not have to work that list out in advance. Run the command: it installs what it
can — Homebrew and the two 1Password applications — and then stops and names exactly what
is left, with the command or click path that fixes each one, before it writes a single
file.

## What happens when you run it

Phases are cut by precondition, never by numeric convention.

- **P0 — preflight.** The part no script can do: the sign-ins and the key registration.
- **P1 — acquisition.** The chezmoi binary, and this repository cloned.
- **P2 — the gate.** Acquires administrator rights and the trust chain, then verifies
  every precondition. Nothing in `$HOME` is touched until it passes.
- **P3 — files.** The managed configuration, applied before the software it configures
  exists.
- **P4 — packages.** Homebrew formulae and casks, the App Store entries, and the one
  tool that has neither.
- **P5 — runtimes.** The pinned language runtimes.
- **P6 — system configuration.** macOS defaults and the Dock.
- **P7 — integrations.** The wiring that only works once the rest is there.
- **The closing report.** What is still missing, re-derived by checking the machine
  rather than by replaying what earlier phases recorded.

The run stops once, at the gate. After that it either completes, or it stops with a
precise instruction and you run it again.

## Afterwards: `drift`

```sh
drift
```

Where does this machine disagree with this repository? Something missing, something
installed that nothing declares, or a managed value that has diverged. It is the one
command of everyday use, it is what the annual review starts with, and it is never
measured between two machines — the repository is the shared reference.

## Deeper

The glossary is in [CONTEXT.md](CONTEXT.md), the structural decisions are under
[docs/adr/](docs/adr/), the review that happens before a wipe is in
[docs/annual-review.md](docs/annual-review.md), and what the machine holds is declared by
the [Brewfile](Brewfile) and the files under `home/`.

## Licence

[MIT](LICENSE).
