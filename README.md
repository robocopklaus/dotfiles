# dotfiles

The source two Apple Silicon Macs are rebuilt from. They are wiped and reinstalled at
least once a year, and this repository restores a working machine from a freshly
installed macOS in one command.

The wipe is a forced review date. So the repository has a second job, and it is the
harder one: every managed entry states why it is here, so that standing in front of the
list next January is a decision and not an archaeology exercise.

It is built for two identical machines and one reader. Onboarding a third machine, or
handing this to someone else, is not a goal — take it as a template, not as a product.
Restoring repositories and working data (`~/Development`, clones, project files) is out
of scope too: that is a backup concern, not a bootstrap concern, and several decisions
here lean on it.

## Where things are

| | |
| --- | --- |
| [**CONTEXT.md**](CONTEXT.md) | The glossary. What the words mean here. |
| [**docs/annual-review.md**](docs/annual-review.md) | The review that happens at the desk, before the wipe. |
| [**docs/adr/**](docs/adr/) | The structural decisions, one file each. |
| [**the map**](https://github.com/robocopklaus/dotfiles/issues/1) | Why the rules are the rules. |

The bootstrap is one command, and it is the only entry point:

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io/lb)" -- -- --use-builtin-git=true init --apply robocopklaus/dotfiles
```

It stops once, at the gate, and tells you exactly what the machine is still missing
before it writes a single file.
