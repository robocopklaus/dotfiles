# dotfiles

The source two Apple Silicon Macs are rebuilt from. They are wiped and reinstalled at
least once a year, and this repository restores a working machine from a freshly
installed macOS in one command.

The wipe is a forced review date. So the repository has a second job, and it is the
harder one: every managed entry states why it is here, so that standing in front of the
list next January is a decision and not an archaeology exercise.

## Where things are

| | |
| --- | --- |
| [**docs/rebuild-specification.md**](docs/rebuild-specification.md) | The specification — the one command, the phases, and everything this repository manages. Normative. |
| [**CONTEXT.md**](CONTEXT.md) | The glossary. What the words mean here. |
| [**docs/adr/**](docs/adr/) | The structural decisions, one file each. |
| [**the map**](https://github.com/robocopklaus/dotfiles/issues/1) | Why the rules are the rules. |

Start with the specification: it opens with the command, and with the preflight — the
preconditions of the run, the ones the gate installs for you and the ones it can only
ask you for.
