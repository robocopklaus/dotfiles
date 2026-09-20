# Rebuilding this Mac from scratch

This repository is the source a Mac is rebuilt from. It is applied to two identical
Apple Silicon machines (a MacBook Pro and a Mac Studio) that are wiped and reinstalled
at least once a year.

The wipe is a **forced review date**, not decluttering and not superstition. So this
repository has two jobs, and the second one is the harder one:

1. Restore a working machine from a freshly installed macOS, in one command.
2. Make the annual review **cheap** — every managed entry states why it is here, so
   that standing in front of the list next January is a decision and not an archaeology
   exercise.

**The mode this repository is built for.** The review happens *at the desk, before the
wipe*. The bootstrap is then pure execution: no decisions, no rediscovery, nothing
pulled back over the following weeks because it was missed. The earlier loop — set up
minimal, restore by irritation — is the thing this design exists to end.

This document is the specification. It is normative for what the repository manages and
how the rebuild runs. Structural decisions are recorded as ADRs under [`docs/adr/`](docs/adr/);
the reasoning behind every rule here lives in the [map](https://github.com/robocopklaus/dotfiles/issues/1)
and its tickets.

---

## 1. The command

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io/lb)" -- -- --use-builtin-git=true init --apply robocopklaus/dotfiles
```

That is the whole entry point. There is no `install.sh` and no prologue script:
`get.chezmoi.io` installs the binary, and `--use-builtin-git=true` clones the source
*before* Xcode Command Line Tools exist — which is the knot a hand-rolled installer
would have to untie again, worse (ADR 0001).

**Re-running this command is the only recovery mechanism.** Every phase is safe to run
any number of times. There is no checkpoint file and no `run_once_` script: a stale
checkpoint that silently skips a phase fails far more confusingly than a slow re-run,
and `run_onchange_` already skips unchanged work by content hash. A phase that cannot
be made idempotent is a bug to fix, not a case to route around with recorded state.

**The run is not input-free, and it is honest about where.** `sudo -v` fires once at the
top of the gate, before any file is written — required because `mas install` needs root
(ADR 0007). That is the single interactive moment. Nothing else pauses: the run either
completes, or it stops with a precise instruction and you re-run it.

---

## 2. Before you type it — the preflight (P0)

Everything below is done by hand, on the fresh machine, before the command. The **gate**
(P2) is the normative source for this list — it is the thing that actually enforces. This
table is a human summary; if it ever disagrees with the gate, the gate is right. In
practice: run the command, and it will tell you exactly what is missing, all of it in one
pass, before a single file is written.

| # | Step | What the gate checks |
| --- | --- | --- |
| 1 | macOS installed, Apple Account signed in in System Settings | macOS >= 26, Apple Silicon |
| 2 | Network | `github.com` reachable |
| 3 | Xcode Command Line Tools — `xcode-select --install` | `xcode-select -p` |
| 4 | 1Password and the 1Password CLI — `brew install --cask 1password 1password-cli` | app present, `op` on `PATH` |
| 5 | Signed in to 1Password, unlocked, **SSH agent enabled** | agent socket exists |
| 6 | Public key registered on GitHub under *SSH keys* **and** *SSH signing keys* | **not verifiable** → closing report |
| 7 | Administrator rights | `sudo -v` |
| — | Signed in with the Apple Account | **not verifiable** → tolerant `mas`, closing report |
| — | Signed in to the App Store | **not verifiable** → tolerant `mas`, closing report |
| — | FileVault | deliberately **not** a gate item |

**The gate reports the remedy, not just the verdict.** Every failed item is printed with
the command that fixes it where one exists, and with the click path where none does. The
remedies live in the gate script beside the checks they belong to — never as a second
column in this table. A list of fix commands maintained apart from the checks it serves
would drift from them, and the copy that drifts is the one that waves you through.

**Why there is no preflight *script*.** The tempting version — one curl-piped script that
*performs* P0 rather than checking it — does not survive its own dependency order:
installing 1Password wants Homebrew, Homebrew wants Command Line Tools, and that is
precisely the wait this design refuses to automate, so the script would stop mid-run and
fetch you anyway. Three of the seven items — the Apple ID, the 1Password unlock and agent
toggle, the GitHub registration — are GUI work no script can perform at all, and they are
the slow ones. It would also be a **second entry point**, fetched and trusted before the
gate exists to check anything, and structurally the least-tested script in the repository,
since CI's runner arrives warm and never exercises bare metal (§8). A script that *checks*
P0 is worse still: it is a second copy of the gate's list, which is rule 1's failure mode
in the one place it is most dangerous.

**Why 1Password is a precondition and not a phase.** P3 writes an `~/.ssh/config` and a
`~/.gitconfig` that are inert until 1Password is installed, signed in, unlocked and has
the SSH agent toggled on — none of which a script can do. It is also the source of the
work identity template (§6.5), which is rendered in P3, before P4 would have installed
`op`. So both the app and the CLI are P0 items; both nonetheless stay declared in the
Brewfile, and casks are installed with `--adopt` so Homebrew takes ownership of the
hand-installed copy rather than colliding with it. One list, one truth.

**Why Homebrew is not a preflight item.** Item 4 is satisfied with `brew`, which means
Homebrew is installed by hand before the run — and it is still not a row of this table.
The vendor's own instructions offer two ways to install the CLI, and the second one, a
downloaded `.pkg`, leaves a copy under `/usr/local/bin` that P4's `--adopt` is in no
position to take over: an unmanaged tail in the one place the trust chain starts. Naming
`brew` in the remedy closes that door without opening a worse one. A row of its own would
have to go one of two ways, and both are worse. With a gate check, the gate would refuse
on something P4 installs unattended anyway — the FileVault argument, applied to the step
most likely to already be there. Without one, the table would list an item the gate does
not know, and the gate is what this list is a summary *of*. Homebrew is therefore not a
precondition of the run; it is how two preconditions are met.

**Why the CLI integration toggle is not gated.** The `op` check verifies the binary on
`PATH`, and the remedy tells you to turn on 1Password → Settings → Developer → Integrate
with 1Password CLI — but nothing verifies the toggle. `op whoami` would, and it is
declined: against a locked vault it raises a GUI unlock prompt, and §1 spends the run's
entire interactive budget on `sudo -v`. A check the gate cannot afford to run is not a
check, so the toggle is unverifiable in the only sense this document uses the word. It
needs no closing-report line either, because it is the one manual step that announces
itself: the very next phase renders the work identity through `op`, and a missing toggle
stops P3 with that template named in the error. The remedy carries it so a human reads it
before that happens.

**Why Command Line Tools is a precondition and not an installation.** The prior setup
polled for up to 3600 seconds waiting for CLT to appear mid-run. That poll is deleted.
An unbounded wait on external state is the single largest violation of "unattended", and
CLT is one of the few things that *can* be satisfied beforehand.

**Why FileVault is not gated.** The gate's mandate is narrow: things without which this
run fails or produces a broken machine. FileVault is neither. A gate that refuses on
things it does not need is a gate you learn to bypass.

There is no "have you signed in? [y/N]" step anywhere. A self-attested checkbox is a
prompt wearing a gate's clothes — it blocks the run while verifying nothing. A manual
step is either **verifiable**, in which case it is a P0 precondition the gate refuses on,
or it is **not**, in which case it can only ever be a tolerant failure plus a line in the
closing report. There is no third category.

---

## 3. The phases

Phases are cut by **precondition**, never by numeric convention. The number records an
order that a precondition justifies; it is never itself the justification.

| # | Phase | Requires | On failure |
| --- | --- | --- | --- |
| P0 | **Preflight** — human, before the command | fresh macOS | run refuses at P2 |
| P1 | **Acquisition** — chezmoi binary + source clone | network | nothing installed yet; re-run |
| P2 | **Gate** — verify P0, acquire privilege | P1 | abort before any file is written |
| P3 | **Files** — managed dotfiles applied | P2 | abort |
| P4 | **Packages** — Homebrew, formulae, casks, `mas`, out-of-band installers | P3, CLT, root | mixed — see below |
| P5 | **Runtimes** — `mise install` | P4 (`mise`) | abort |
| P6 | **System configuration** — macOS defaults, Dock | P4 (apps), non-root | abort |
| P7 | **Integrations** — post-install wiring | P2 (the 1Password agent) | tolerant |
| 9x | **Epilogue** — the closing report | — | never fails the run |

**P2 — the gate.** A `run_before_` script, and the structural addition the prior setup
lacked entirely. It checks **every** P0 item and reports **all** failures in one pass,
each with its remedy (§2). Running before file application means a failed gate leaves the
machine completely untouched. Under CI the 1Password items degrade from refusing to reporting
(§8); every other precondition still refuses.

**P3 — files before tools.** Configuration lands before the software it configures
exists. This is deliberate: a config file is inert until its tool arrives, so the SSH
config pointing at the 1Password agent is written in P3 and becomes meaningful in P4.

**P4 — the only phase that touches root.** Internal order is load-bearing: formulae
first as the blocking base, then casks, then `mas`, then the out-of-band Claude Code CLI
(§6.1), which is last because nothing waits on it. The gate validated that `sudo` works;
P4 starts its own keepalive, because each chezmoi script is a separate process and a
keepalive started in P2 cannot be adopted here. Cask installers prompt at unpredictable
points during a bundle run, which is why the keepalive exists at all. The CLI script is
the exception and takes no keepalive: its installer writes only under `$HOME` and refuses
outright to run through `sudo`.

**P7 — the source remote.** One thing occupies the phase: the chezmoi source remote is
rewritten from HTTPS to SSH, once the 1Password agent is there to carry it (§6.5). The
inherited integration that would otherwise have lived here was an `obsidian-cli` symlink,
and Obsidian is out of scope (§6.3) while `obsidian-cli` is not declared anywhere in the
inventory (§6.1) — an integration that wires up a tool the repository does not install has
nothing to do.

### Failure behaviour

One rule: **a phase aborts the run only if a later phase depends on it.**

- **Abort** — the gate, Homebrew itself, formulae (P5 needs `mise`, P6 needs `dockutil`).
- **Degrade and report** — casks and `mas` apps, installed individually so one bad GUI
  app cannot kill a fresh bootstrap, and the out-of-band Claude Code CLI (§6.1), which
  nothing waits on. Collected failures surface in the closing report with an instruction
  to re-run.

A tolerant phase must have tolerant dependents: P7 depends on the 1Password agent, which
the gate refuses on for a real Mac and merely reports under CI (§8), so P7 skips cleanly
when the socket is absent rather than failing.

### The closing report re-derives; it never replays

Each chezmoi script is a separate process, so failures cannot be accumulated in memory.
The obvious fix — a scratch file the phases append to — is exactly the recorded
intermediate state the convergence invariant bans, and it has the same failure mode:
after a re-run it goes stale, and then it lies.

So the epilogue **re-checks the world**: `brew bundle check`, is the agent socket there,
does `mise` resolve, did the work identity actually render. It is derived from current
state, so it cannot age, and it is correct on the first run and the fifth alike. Its
output has two parts:

- **Dynamic** — what is missing right now. This is the `drift` command (§7), invoked as
  the run's tail.
- **Static tail** — what no script can perform or verify: the sign-ins other things
  depend on, the account-restored applications (§6.3), and the *paths* credential files
  are expected at — paths only, never values, so a rebuilt machine says `ha` will want
  `~/.ha-cli.env` from 1Password. Credential files are never P0 gates; they block a CLI,
  never a later phase.

---

## 4. Repository layout

```
.
├── .chezmoiroot                            → "home"
├── .github/workflows/                      lint.yml, e2e.yml
├── .gitignore                              what this repository produces (§5.1)
├── Brewfile                                the inventory (§6.1)
├── Brewfile.work                           the work group (§6.1)
├── CLAUDE.md
├── CONTEXT.md                              the glossary — the language, nothing else
├── README.md                               the front door, and a pointer here
├── docs/adr/   docs/agents/
├── docs/rebuild-specification.md           ← this specification
├── tests/
│   ├── drift.sh                            drift's own logic, stubbed (§7)
│   ├── identity.sh                         which identity a remote selects (§6.5)
│   └── *.bats                              bats: idempotency only
└── home/                                   ← the entire chezmoi source
    ├── .chezmoidata/macos-defaults.toml    the defaults declaration (§6.4)
    ├── .chezmoidata/dock.toml              the Dock declaration (§6.4)
    ├── .chezmoitemplates/lib/               shared shell and one shared read, at render time
    │   ├── work-identity.json               the 1Password item, shared by five surfaces (§6.5)
    │   ├── agent-socket.sh                  the agent's socket path, shared by 20 and 70
    │   ├── homebrew.sh                      the prefix cascade
    │   ├── keepalive.sh                     the sudo keepalive, shared by 40 and 41
    │   ├── macos-defaults.sh                the declaration, shared by 60 and drift
    │   ├── dock.sh                          the layout, shared by 61 and drift
    │   └── dock-restart.sh                  the one restart rule, shared by 60 and 61
    ├── .chezmoiscripts/
    │   ├── run_before_20-gate.sh.tmpl                   P2
    │   ├── run_onchange_after_40-homebrew.sh.tmpl       P4  formulae + casks
    │   ├── run_onchange_after_41-mas.sh.tmpl            P4  separate: needs root
    │   ├── run_after_42-claude-code.sh.tmpl             P4  separate: no brew
    │   ├── run_onchange_after_50-mise.sh.tmpl           P5
    │   ├── run_onchange_after_60-macos-defaults.sh.tmpl P6
    │   ├── run_onchange_after_61-dock.sh.tmpl           P6
    │   ├── run_after_70-remote.sh.tmpl                  P7  the source remote, → SSH
    │   └── run_after_99-report.sh.tmpl                  epilogue — invokes drift
    ├── dot_local/bin/executable_drift.tmpl              → ~/.local/bin/drift
    ├── dot_zprofile.tmpl
    └── dot_config/…  private_dot_ssh/…                  (§6.3)
```

**`.chezmoiroot`, not `.chezmoiignore`** (ADR 0005). Both can express this tree; they
differ in the direction they fail. An ignore list is a denylist — the line you forget
writes an unexpected file into `$HOME`, silently. Under `.chezmoiroot` a file forgotten
outside `home/` is simply not applied: visible, harmless. `.chezmoiignore` is deleted
outright; chezmoi's own `.chezmoi*` directories never reach `$HOME`, so nothing remains
to list.

**`.gitignore` declares only what this repository produces.** Machine-wide noise is
declared once, in the global ignore this repository manages (§6.3); repeating it here
would be a second list (§5.1). It is a denylist, and ADR 0005's argument reverses here:
a forgotten deny line surfaces as an untracked file in the status output — visible,
harmless — while a forgotten allow line under `.claude/*` would silently drop a shared
file from the repository.

**One script per precondition; the tens digit names the phase.** P4 is three scripts
because it has three preconditions: `mas` needs root, and the Claude Code installer needs
network but not Homebrew. 40/41/42 read as visible siblings — the fix for the prior
10/20/30/40/50/60, where nothing explained the gaps.

**42 is `run_after_`, for the same reason the epilogue is.** 40 and 41 inline the Brewfile,
so their rendered content changes whenever the inventory does and `run_onchange_` re-triggers
by construction. 42 inlines nothing, so its content never changes — `run_onchange_` would
run it exactly once per machine, which is a `run_once_` wearing a different prefix, and §1
bans that: a machine whose CLI went missing would never get it back from the one command
that is supposed to be the whole recovery mechanism. So it re-derives on every run, and its
presence guard makes a converged run cost one `command -v`.

**70 is `run_after_` for the neighbouring reason.** It inlines nothing either, and its
content hash says nothing about the value the source remote currently holds — so the rewrite
would be attempted once per machine and never looked at again (§6.5).

**`9x` is deliberately outside the phase range.** The closing report is the run's
epilogue, not a phase; numbering it `80` would imply a P8 that does not exist. It is
`run_after_`, not `run_onchange_after_`, because it re-derives state on every run by
design — content-hash skipping would be precisely wrong for it.

**Every script carries a header**, two fields: `# Phase:` and `# Requires:`. The numeric
prefix records an order a precondition justifies and never justifies it itself, which
leaves the justification homeless unless the script states it. CI checks that both fields
are present and never reads the prose.

**Shared shell is a `.chezmoitemplates` include, not a sourced file.** Two of the three
reasons are correctness rather than taste: `run_onchange_` hashes the *rendered* script,
so editing a runtime-sourced helper would leave every consumer stale and never re-run;
and CI lints rendered scripts, where `source` of a runtime path is unfollowable by
shellcheck (SC1090) — the helper would become the one piece of shell CI never checks.

**The Brewfile sits at the root and is inlined at render time** via
`{{ include "../Brewfile" }}`, piped to `brew bundle --file=-`. The content is *in* the
rendered script, so `run_onchange_` re-triggers on any edit by construction: no `sha256`
comment, no `$CHEZMOI_SOURCE_DIR` lookup at runtime. The most-edited file of the annual
review belongs at the top level. `Brewfile.work` sits beside it and is inlined the same
way, inside the guarded branch described in §6.1.

**The defaults and Dock declarations sit under `home/.chezmoidata/`** because
`.chezmoidata` loads them into the template data context, so both the applying script and
the drift check read them directly. At the root, both would need
`fromToml (include "../…")` — a hand-rolled re-implementation of the mechanism, in two
places. Knowing cost: the two surfaces a human edits during the annual review end up in
different places.

---

## 5. Standing rules

These apply everywhere and are the ones most likely to be violated by accident.

1. **One list, one truth.** Never two declarations of the same fact. Every "second
   list" proposal in this repository's history has been rejected on this ground, and
   every one that slipped through has drifted (`zen` cut from the inventory but still
   fifth in the Dock; Keynote cut but still installed).
2. **`brew bundle dump` is never run against this repository.** It reads installed state
   and truncates the target file wholesale — there is no merge path — so it would erase
   every reason comment in the Brewfile (§6.1). The Brewfile is hand-written.
3. **The repository declares zero secrets** (§6.5).
4. **Nothing stores a "last confirmed" date.** Staleness is re-derived from the machine at
   review time (§9). A field nobody updates does not degrade to "no information"; it
   degrades to a confident lie.
5. **Generality arrives with the second real consumer.** Name the second call site, or the
   layer does not go in.
6. **Guards derive from the machine, not from a flag** — whether `op` is on the path, not
   an environment variable someone sets. A flag is a second truth that can be set wrongly.
   The one exception is `CI`, which the runner sets and this repository never writes, so
   it is environmental fact rather than configuration.

---

## 6. What the repository manages

### 6.1 Applications and tools — the Brewfile

The Brewfile is the **full truth of the machine**, save one entry neither Homebrew nor the
App Store can carry, which is named below rather than left out. There is no unmanaged
tail: an unmanaged tail means the wipe still silently deletes things, which is the
review-through-the-wipe loop wearing a new hat.

**Every entry carries one trailing `#` comment stating its role, and nothing else.**

```ruby
brew "zoxide"                 # z — directory jumping
brew "jq"                     # Bootstrap dependency: scripts parse JSON
cask "finicky"                # Routes URLs between browsers; background app, so no launch record by design
mas  "Pages", id: 361309726   # Documents
```

Role, not evidence. `572 invocations` and `Sep 16` were true in September 2026 and are
meaningless by January; they stay in the review record, not in the tree where they decay.
Where an **exemption** exists it is written down — `# Background app, so no launch record
by design` earns its place precisely because it stops a future review re-cutting something
an earlier one already examined.

Trailing rather than preceding is deliberate: `brew bundle dump` emits a *preceding*
full-line comment carrying the upstream package description, a machine convention that
means something else.

**One `tap` line comes first.** `homebrew/command-not-found` is not an application but
the data behind one: the zsh plugin of §6.3 is inert without it, and on macOS it fails
silently rather than loudly. It carries a role comment like every other entry. It is the
only tap — Homebrew's own defaults cover the rest of this inventory.

**Structure: the `brew` / `cask` / `mas` split, and nothing else.** No thematic headers.
The type split survives because the bootstrap already partitions on it; "Daily tools"
earns nothing, and once every line states its own reason a header is a second and coarser
answer to the same question. Homebrew has no native grouping — and silently accepts and
ignores unknown options, so `brew "jq", group: "core"` parses, exits 0, and does nothing.
Named here so it is never reached for.

**CI enforces that a reason is present, never what it says** (§8). A check that judged
quality would be satisfied by `# tool` and would have to be argued with; a presence check
just makes the omission loud at the moment the entry is added, which is the only moment
the reason is actually known.

#### The sourcing rule (ADR 0007)

Two clauses, applied in order:

1. **If it restores itself from an account, the repository declares nothing.**
2. **Of what remains, the App Store only where no cask exists** — a fallback, never a
   preference.

`brew search --cask` decides the second clause, so it is a fact rather than a judgement,
and the App Store population is **closed by construction**. No future entry can reach it
through a preference, and the annual review never re-asks "should this have come from the
App Store"; it asks only whether a cask has appeared since. Where both exist, Homebrew
wins — the reason that matters here is that every App Store entry widens the Apple ID gap,
which is the one precondition the gate cannot verify and CI must degrade under.

#### Base — CLI (14)

| Entry | Role |
| --- | --- |
| `chezmoi` | Drives the entire bootstrap |
| `git` | Version control |
| `gh` | GitHub CLI — issues and this repository's map live there |
| `jq` | Bootstrap dependency: scripts parse JSON |
| `mas` | Bootstrap dependency: installs the App Store entries |
| `dockutil` | Bootstrap dependency: reconciles the Dock |
| `mise` | Runtime manager |
| `uv` | `uvx` one-shot runner for Python CLIs — *not* the Python runtime manager, which is `mise` |
| `antidote` | zsh plugin manager, loaded by every shell |
| `oh-my-posh` | Prompt, rendered by every shell |
| `zoxide` | `z` — directory jumping |
| `cloudflare-cli4` | Personal infrastructure |
| `gogcli` | Google Suite CLI — Gmail, Calendar, Drive, Docs, Sheets |
| `homeassistant-cli` | Home automation |

#### Base — applications (17 casks, 4 App Store)

| Entry | Role |
| --- | --- |
| `1password` | Password manager; root of the bootstrap trust chain |
| `1password-cli` | `op` — renders the work identity; trust chain |
| `claude` | Primary coding agent — the desktop application only; the CLI is out of band, below |
| `visual-studio-code` | Editor |
| `ghostty` | Terminal |
| `google-chrome` | Browser |
| `slack` | Messaging |
| `raycast` | Launcher |
| `mimestream` | Mail |
| `obsidian` | Notes |
| `clockify` | Time tracking |
| `chatgpt` | Assistant |
| `whatsapp` | Messaging |
| `codex` | Coding agent |
| `docker-desktop` | Containers |
| `finicky` | Routes URLs between browsers; background app, so no launch record by design |
| `font-meslo-lg-nerd-font` | Bootstrap dependency: the glyphs `oh-my-posh` renders |
| Pages — `361309726` | Documents; no Homebrew cask exists |
| Numbers — `361304891` | Spreadsheets; no Homebrew cask exists |
| GCal for Google Calendar — `1107163858` | Calendar; no Homebrew cask exists |
| 1Password for Safari — `1569813296` | Safari extension; no cask, and no launch record by design |

#### Out of band — the Claude Code CLI

One installed thing reaches the machine through neither Homebrew nor the App Store, and it
is named here rather than left to the unmanaged tail §6.1 opens by refusing. The Claude
Code **CLI** has no formula and no cask, so it comes from its own installer, in its own P4
script (§4). Its precondition is network, not Homebrew, which is exactly what cuts it away
from the bundle run.

**The `claude` cask is the desktop application, and that is the whole of the distinction.**
Two artifacts, two sources, one name — which is why both entries say so rather than leaving
the next review to rediscover it. The CLI is the `claude` on `PATH`, installed under `$HOME`
and self-updating thereafter, so the bootstrap's only job is that it exists at all.

This does not reopen the sourcing rule. ADR 0007 arbitrates between Homebrew and the App
Store for a thing both could carry; this is a thing neither can, so it is a gap in the two
mechanisms rather than a preference between them, and the rule's population stays closed by
construction. Should a formula ever appear, the entry moves into the Brewfile and the script
is deleted — that is the one question the annual review asks here.

#### The work group (5)

`azure-cli`, `databricks`, `jira-cli`, `gcloud-cli`, `microsoft-teams` — real tooling in
weekly use, held in a **second Brewfile, `Brewfile.work`**, at the repository root beside
the base one, inlined into the P4 Homebrew script and piped to a second
`brew bundle --file=-`.

The file carries one line that is not an entry: `databricks/tap`, which homebrew/core does
not carry the CLI in. It sits in this file rather than beside the base tap for the reason
the file exists — the deletion that removes the group removes its tap with it.

**It rides the guard that already exists.** The include sits inside the *same*
`op`-presence branch §6.5 puts on the work identity, so the identity and its tooling turn
on and off as **one fact under one guard**. No flag, no chezmoi config value, no second
file format — rule 6 asks for a machine-derived fact, and this one was already being
derived for the surface next door.

**It is not "optional" in the sense of a per-machine choice.** Both Macs are company
machines and both install all five; the only renderer that ever omits the group is CI.

**What the split buys is lifecycle — at the company's level, not a client's.** The work
is done through one company for several clients, so ending *one* client relationship is
not one deletion. It is a walk through `Brewfile.work` asking which entries were theirs,
which is the per-entry judgement the split exists to avoid. What the file does buy in a
single deletion is the whole surface at once: the day this repository stops carrying
client work, `Brewfile.work` and its include line go and no entry in the base is touched.
That is a weaker claim than the one a single engagement would support, and it is the one
that is true.

Weaker, so it is worth naming what still holds the file apart from the base. Two things,
and only two: the base inventory stays a statement about the machine rather than about
whose work it does, and CI is spared 1.5 GB of client tooling it would never open (below).
Neither is the lifecycle argument, and if both ever stop mattering the honest move is to
merge the five into the base rather than keep a file whose stated reason has drained out.

The guard is a **proxy**, and a closer one than it first reads: `op` on the path means
"1Password is installed", which stands in for "this is a company machine". Both Macs are,
CI is not, and no third kind of machine applies this repository — there is no personal Mac
in the fleet for the proxy to be wrong about. It is the right proxy because the true fact
— resolving the work-identity item itself — would be a second and finer discriminator for
the same relationship, with exactly one consumer (rule 5), guarding against a machine that
does not exist. And ADR 0004's refusal to derive CI from `op`'s *absence* does not reach
here: that ambiguity — a genuinely fresh Mac has no `op` either — lives at the **P2 gate**,
while the group renders at **P4**, after the gate has already refused every real Mac
lacking `op` (P0 item 4). By P4, CI is the only op-less renderer left.

`drift` needs no special case for the group. The check is rendered by chezmoi too, so it
evaluates the same guard at the same moment as the applying script: on a company Mac the
five are declared *and* installed, on CI they are neither — clean either way, and never
reported as *Not in the repository*. That is also the guard's second consumer, which is
what rule 5 asks of any shared mechanism.

The price, stated: CI never installs the group and so never exercises the second
`brew bundle --file` invocation (§10). Applying it unconditionally was the runner-up and
is not absurd — it would have CI run exactly what the Macs run. It loses on price. The
group costs roughly 1.5 GB per run, 1.1 GB of that a GUI chat client installed into a
headless runner that will never open it, to prove that `brew bundle --file=-` works a
second time.

**The reasons state the role, never the client.** The trailing-comment convention above
applies unchanged, but this is the one file where the temptation to explain *whose* stack
it is runs strongest. `# Azure CLI — client cloud platform`, never a client's name: the
five entries are generic and leak nothing by themselves, so the comments are the leak
surface.

Serving several clients helps here rather than hurting. The set says the company works
with cloud platforms and a ticket tracker; it does not say which client brought which
entry, because more than one did. That is second-order comfort and not the rule — the
rule is still the comments.

#### What the bar is

**Demonstrated use.** If an entry leaves no trace between two reviews it goes; "cheap to
reinstall on demand" is the standing answer to "but what if". There is no second, softer
threshold for barely-used tools — "it left a trace" is checkable next January, "it didn't
feel like enough" is not. Two exceptions, both written into the entry's own reason:

- **Bootstrap dependencies** are kept because a script invokes them, never because they
  are typed.
- **Background applications** — a URL handler, a sync daemon, a browser extension — have
  no launch record by design, so absence of one cuts nothing.

### 6.2 Runtimes

`mise`, pinned in `~/.config/mise/config.toml`, installed in P5. `mise ls` already diffs
its own configuration, so runtimes are not swept by the drift command (§7).

### 6.3 Configuration files (ADR 0006)

A configuration is managed as a file **iff** it is:

1. **plain text** — not a feasibility nicety. Raycast's settings are hand-authored in
   every meaningful sense but live in an encrypted, device-bound SQLite store; there is no
   file to commit.
2. **predominantly human-authored** — several real files have two authors, and this clause
   is what separates them.
3. **never a secret, whatever its shape** — stated outright, because the rule without it
   reads as "commit your Cloudflare token".

The rule is a property of the **file**, not of its directory, and it is written that way
even though nothing managed sits outside `~/.config` and `$HOME` today. An editor's
`settings.json` under `~/Library/Application Support/` would qualify on its contents
alone, and the boundary should not have to be renegotiated when one does.

**Managed (13 paths):**

| Path | Reason |
| --- | --- |
| `dot_config/ghostty/config` | Terminal; hand-written |
| `dot_config/finicky/finicky.ts` | URL routing rules; all human |
| `dot_config/oh-my-posh/config.omp.json` | Prompt definition |
| `dot_config/mise/config.toml` | Runtime pins |
| `dot_config/ccstatusline/settings.json` | Statusline definition |
| `dot_gitconfig`, `dot_gitignore` | Global git behaviour and the `includeIf` set that selects an identity; templated, because the client-issued half of that set is guarded (§6.5) |
| `dot_config/git/allowed_signers`, `config-work` | Signing and the client-issued identity; templated (§6.5) |
| `dot_config/git/config-personal`, `config-company` | The two cleartext identities, each included by remote (ADR 0011) |
| `dot_claude/settings.json` | Permissions and hooks — see the dominance note |
| `dot_mcp.json` | Fully hand-authored |
| `dot_editorconfig` | Editor defaults |
| `dot_zshrc`, `dot_zprofile`, `dot_zsh_plugins.txt` | Shell; `zsh_plugins.txt` is antidote's declaration |
| `private_dot_ssh/private_config` + `id_personal.pub`, `id_work.pub` | Templated (§6.5) |
| `dot_config/1Password/ssh/agent.toml` | Which vaults the SSH agent may offer keys from; hand-written, and names no item (§6.5) |

**On dominance.** `~/.claude/settings.json` is written back by its own application. It
stays managed anyway: deliberate configuration is not discarded to protect a principle,
and write-back is just drift, which the report already surfaces (§7). Re-adoption is a
deliberate `chezmoi add`.

**Not managed — and the mechanism is identical in all four cases: the repository does
nothing. Only the recorded reason differs.**

- **Account-restored** — Raycast, Slack, Chrome (including its extensions — Chrome sync
  installs them, which is why signing into Chrome is not a P0 item), ChatGPT, Mimestream,
  Clockify, WhatsApp, 1Password, GCal, Docker Desktop, and the editor's whole surface —
  VS Code's Settings Sync carries its `settings.json`, extensions and keybindings
  together, so splitting the file out to manage it here would be the one entry whose two
  copies could disagree.
- **Out of scope** — **Obsidian.** All four vaults live under `~/Development/`, inside the
  data-restore zone this effort excludes; per-vault `.obsidian/` is versioned with each
  vault's own repository, and `obsidian.json` is a machine-written registry of absolute
  paths into directories that will not exist.
- **Accepted lost** — `~/.config/gh/config.yml` (stock boilerplate around one human line)
  and `~/.codex/config.toml` (four hand-written lines under ninety-seven machine-appended
  ones, whose project paths point into the out-of-scope zone anyway).
- **Secrets, never managed** — `~/.ha-cli.env`, `~/.cloudflare`, `~/.firefly_token`,
  `~/.ghostfolio_token`. These satisfy clauses 1 and 2 completely; only clause 3 stops
  them. Their *paths* appear in the closing report's static tail; their values never leave
  1Password.
- **No user-facing configuration at all** — `chezmoi`, `gh`, `jq`, `mas`, `dockutil`,
  `uv`, `zoxide`, `gogcli`, `cloudflare-cli4`, `homeassistant-cli`,
  `1password-cli`, `font-meslo-lg-nerd-font`, Pages, Numbers, 1Password for Safari. Named
  so the omission is a stated choice. The work group manages no configuration today
  either: those tools keep machine-written auth caches, which fail clause 2.

**Reasons live in this table, not in the files.** The Brewfile's trailing-comment
convention does not transfer — these are files rather than list entries, they share no
comment syntax, and several are JSON, where a comment is a syntax error. There is no CI
check for the same reason.

#### Agent skills and plugins: the repository declares none (ADR 0010)

An entry belongs in the **cheapest mechanism that can hold it**, measured in what a
rebuild must do to restore it:

1. the **claude.ai account** — costs nothing and keeps itself current;
2. a **project's own checked-in `.claude/settings.json`** — costs nothing here, because
   repositories are out of scope, *provided the project actually is a clone*;
3. **this repository** — costs a bootstrap step plus a line in the annual review.

This repository therefore declares only what neither of the first two can hold, and on
this surface that set is currently **empty** — including third-party and private
marketplaces, which ride the account sync as long as they are GitHub repositories. The
account holds a GitHub authorization, not an SSH key, so the boundary is *GitHub versus
not*, and every marketplace in use here is a GitHub repository. `enabledPlugins` and
`extraKnownMarketplaces` do **not** appear in the managed `~/.claude/settings.json`; no
install loop is written in P7.

Two things this rests on, and both are the rebuild's business:

- **Sync is not instant.** A newly enabled marketplace took roughly thirteen minutes to
  land in `~/.claude/plugins/synced/`. A freshly rebuilt machine should not treat agent
  tooling as present the moment you log in.
- **Curating the account is the responsibility this decision buys.** A plugin installed
  locally but never enabled on the account does not survive a wipe, silently — the same
  failure this repository exists to end, moved one level up.

`~/.cursor/skills/` is out of scope: Claude Code reads only `~/.claude/` and a project's
`.claude/`, so managing both would store one set of skills twice.

### 6.4 macOS defaults and the Dock

**Managed defaults are declared as data** — `domain`, `key`, `type`, `value` — in
`home/.chezmoidata/macos-defaults.toml`, with both the applying script and the drift
check derived from that one declaration (ADR 0002). This is not a style preference. A
`run_onchange_` script appears in `chezmoi status` only when *its own content* changes;
tampering with what it produced leaves the status clean. chezmoi tracks a script's content
hash, not its effect, so a default changed in System Settings is invisible to every check
this repository has unless the expected value is declared as data something can read.

**They are applied unconditionally, on every apply.** The prior opt-in flag
(`CHEZMOI_APPLY_MACOS_DEFAULTS`) is deleted: a gate that defaults to off means a rebuilt
machine comes up unconfigured, which is the rediscover-by-irritation loop again. The
concern the flag actually guarded — a routine `apply` yanking the Dock and killing Finder
mid-workday — is solved properly instead of optionally: **an app is restarted only when a
key in its own domain actually changed**, which the data declaration makes trivial to
compute. A mid-workday apply is then a no-op in practice. `killall SystemUIServer`
disappears entirely; no managed key remains in a domain it owns.

The prior setup's ~60-line plist backup, its retention constant and its prune routine are
**deleted**. They guarded a scenario that never occurred, with a recovery — restore a
whole domain to undo one key — nobody would use. The genuine safety net is that the
declaration is a short reviewable list in git, and the drift report names any key the
machine disagrees with.

A package you do not have is an absence; a system setting you do not have is a *wrong*
setting, because macOS always supplies its own value. That is why the guarded second-file
pattern from §6.1 deliberately does not extend here.

**The managed 22:**

| Domain | Key | Type | Value |
| --- | --- | --- | --- |
| `com.apple.dock` | `tilesize` | int | `36` |
| `com.apple.dock` | `show-recents` | bool | `false` |
| `com.apple.dock` | `autohide` | bool | `false` |
| `com.apple.finder` | `_FXSortFoldersFirst` | bool | `true` |
| `com.apple.finder` | `NewWindowTarget` | string | `PfHm` |
| `com.apple.finder` | `NewWindowTargetPath` | string | `file://${HOME}/` |
| `com.apple.finder` | `FXDefaultSearchScope` | string | `SCcf` |
| `com.apple.finder` | `ShowPathbar` | bool | `true` |
| `com.apple.finder` | `ShowStatusBar` | bool | `true` |
| `com.apple.finder` | `FXPreferredViewStyle` | string | `clmv` |
| `NSGlobalDomain` | `com.apple.mouse.tapBehavior` | int | `1` |
| `NSGlobalDomain` (`-currentHost`) | `com.apple.mouse.tapBehavior` | int | `1` |
| `com.apple.AppleMultitouchTrackpad` | `Clicking` | bool | `true` |
| `com.apple.AppleMultitouchTrackpad` | `Dragging` | bool | `true` |
| `com.apple.AppleMultitouchTrackpad` | `TrackpadThreeFingerDrag` | bool | `true` |
| `com.apple.driver.AppleBluetoothMultitouch.trackpad` | `Clicking` | bool | `true` |
| `com.apple.driver.AppleBluetoothMultitouch.trackpad` | `Dragging` | bool | `true` |
| `com.apple.driver.AppleBluetoothMultitouch.trackpad` | `TrackpadThreeFingerDrag` | bool | `true` |
| `NSGlobalDomain` | `KeyRepeat` | int | `2` |
| `NSGlobalDomain` | `InitialKeyRepeat` | int | `15` |
| `NSGlobalDomain` | `ApplePressAndHoldEnabled` | bool | `false` |
| `com.apple.screencapture` | `location` | string | `~/Downloads` |

The boolean values carry the prior setup's declaration, which was verified against the
live machine: 28 of its 29 keys still held their declared values after months of use. The
one divergence was `com.apple.dock autohide`, and it was the *declaration* that was stale,
not the machine — it is now declared `false`, which takes `autohide-delay` and
`autohide-time-modifier` with it.

**Seven keys were cut** and are named so they are not re-added by reflex: Dock
`magnification` and `largesize` (cosmetic), Dock `autohide-delay` and
`autohide-time-modifier` (dead once autohide is off), Finder
`ShowExternalHardDrivesOnDesktop` and `ShowRecentTags` (never consciously noticed), and
Finder's `DesktopViewSettings:IconViewSettings:arrangeBy`. That last cut is the
load-bearing one: it was a PlistBuddy path into a nested dictionary, which
`domain/key/type/value` cannot express. Cutting it means **every managed default is now
flat**, with no escape-hatch branch, which is what keeps the declaration a table and the
drift check derivable from it.

**The bar for a setting:** you would re-set it by hand on a fresh machine, and its absence
would annoy you within the first hour. Keys that fail loudly stay; cosmetic keys that fail
silently are cut. This list is also the only lever on the drift report's size, since the
report enumerates declarations rather than the machine — so a default that is noisy in the
report is a default that should not be managed.

One consequence accepted knowingly: some trackpad keys are read by the window server at
login, so on a running machine a trackpad change may lag until the next login. On a fresh
bootstrap that is free.

#### The Dock (ADR 0009)

The Dock's layout is managed, and it is **reconciled, not rebuilt**: read the current tile
sequence, compare it to the expected one, and rebuild through `dockutil` only on mismatch.
On a converged machine this is a silent no-op — no clear, no rebuild, no `killall`. The
plist backup and its five-deep prune are deleted along with the destructive rebuild they
insured against.

This is measured rather than assumed: after four months the live Dock still matched the
prior declaration exactly, all 23 tiles in order, both folders, all six spacers. The usual
objection — that managing the Dock means every apply fights a Dock you have since
rearranged — has no evidence behind it here.

**Declared as ordered categories** in `home/.chezmoidata/dock.toml`, beside but *not*
inside the defaults table. The two share the `com.apple.dock` domain but not their shape,
and the defaults table's flatness is what ADR 0002 depends on. Spacers are **generated**
after each category that still has a member, so a category emptied by a future review
leaves no stray separator. The two folders close the sequence with their display options.

The current sequence, in six categories:

| Category | Tiles |
| --- | --- |
| Media | Music |
| Browsers | Safari, Chrome |
| Communication | Mail, Mimestream, Slack, Messages, WhatsApp |
| Work | ChatGPT, Claude, GCal, Calendar, Obsidian |
| Development | VS Code, Ghostty |
| System | System Settings |

**A Dock entry is a reference to an application the repository already declares, never a
second declaration of it**, and CI enforces the direction: every name in `dock.toml` must
resolve to a Brewfile entry or an Apple system application. The check is not
precautionary — `zen` was cut from the inventory as the clearest cut in the list and was
still sitting fifth in the Dock declaration. Two lists, one truth, already drifted. Zen is
gone from both.

**One restart rule.** Two managers of one domain is accepted, because the layout genuinely
cannot be flat `domain/key/type/value`. Two restarts of one app is not: the layout step
reports its change into the same restart mechanism the defaults use, and a single
`killall Dock` at the end of the run covers both. The defaults step records its change
rather than acting on it, because the restart has to come *after* the layout is written.

One consequence accepted knowingly, and named here so the annual review answers it in one
line rather than rediscovers it: both steps are `run_onchange_`, so an apply that changes
only the defaults table runs 60 without 61, and the recorded restart is then carried to
61's next run rather than performed in that one. The Dock picks the change up at the next
restart either way, and the cost when it is carried is one restart on a later apply that
found the layout converged. The alternative is a layout step that re-derives on every run
— which is what `9x` and `42` are, and what this one would become if the carry ever
stopped reading as a footnote.

### 6.5 Secrets, SSH and signing (ADR 0003, ADR 0008, ADR 0011)

**1Password stays**, in all three roles: SSH agent for authentication, `op-ssh-sign` for
commit and tag signing, and the store for tokens. Dropping it for on-disk keys would
delete three preflight items, but it trades a *verifiable* precondition for an
unverifiable secret-restore problem, and puts private keys on disk to do it.

**The repository declares zero secrets.** Not one `op://` reference. Tokens are fetched by
hand when a tool first needs one. The alternative — a fully-logged-in machine on first
boot — buys convenience at a structural price: every `chezmoi apply`, on every machine,
would depend on an unlocked vault, so the bootstrap could fail for a reason unrelated to
anything it was asked to do. Correspondingly, `gh auth login` is neither a gate item nor a
line in the closing report's static tail; nothing in the bootstrap depends on `gh`.

**Three identities commit from this machine, and none of them is the default** (ADR 0011).
The **personal** identity, the **company** identity — 21st digital, under which client work
on github.com is done — and the **client-issued** identity, whose account and hosts belong
to a client. They are selected by two rules, because two things are being decided. *Key
material belongs to the account that verifies it*: personal and company share one github.com
account and therefore one key; the client-issued identity has its own account and its own.
*The address belongs to the engagement*: `user.email` is chosen per repository by
`includeIf "hasconfig:remote.*.url:…"`, keyed on the remote, because the remote is what
decides which account will verify the signature.

`~/.gitconfig` carries no `user.email` at all. It holds what every identity shares —
`user.name` and the signing setup — and `user.useConfigOnly = true`. A repository that no
`includeIf` matches **refuses to commit** rather than falling back. Every default is wrong
somewhere and wrong *silently*: a personal default signs paid work with a private address, a
company default writes an employer into a repository that outlives the employment. Refusal
is loud, arrives at the first commit, and costs one line to resolve. It also removes the
need to enumerate client organisations in a public tree in order to avoid a default — which
is the same relationship §6.5 exists to keep out of it.

**The one exception is the client-issued identity** — the *work identity* in the tree,
whose filenames stay neutral — rendered from a **single** 1Password item via
`onepasswordRead` templates. Nothing in it is cryptographically secret — the signing key is
a *public* key and the GHE host is a *public* DNS name. What is kept out of a public tree
is the **client relationship**. So the unit is the whole identity, indivisible: its hosts —
one issuing account answers on more than one, and the git and ssh patterns are derived from
them rather than written out by hand (ADR 0011) — name, address, signing key, its
`allowed_signers` line, and the ssh `Host` block.
Half-evicting it — hiding the email, leaving the hostname — reveals the same fact for none
of the benefit.

**The filenames leak too**, so they are neutral: `config-work`, `id_work.pub`. The
1Password item's own name and vault appear in the public tree as a pointer, so the item
must not name the client either. The personal identity, its key and its `allowed_signers`
line stay in cleartext — they are already public on GitHub.

**The item is named once.** The five surfaces that render from it — the `includeIf` in
`~/.gitconfig`, `config-work`, the `allowed_signers` line, the ssh `Host` block and
`id_work.pub` — all read one `.chezmoitemplates` partial, which is the only place the item
and its field names are written down. That is also why `~/.gitconfig` is templated at all:
the condition that switches the identity on is the host pattern, which leaks exactly what
the file it includes does, so it is rendered under the same guard and is simply absent on a
machine without `op`, where the file it would point at is not written either.

**An `op`-less machine degrades; it does not refuse.** The work-identity templates are
guarded on `op` being present, so CI and any machine without 1Password render a
personal-only configuration that applies cleanly. This is not a convenience — it is what
keeps the design testable. A mechanism that only works at one desk is untested by
construction, and giving CI a stub `op` was rejected for the same reason: the templates CI
proved would not be the templates that run. The refusal stays in the gate; the template
layer does not refuse a second time.

**The same guard carries the work group** (§6.1). The client relationship is one fact, so
its identity and its tooling are switched by one condition rather than by two that can
disagree.

Two consequences, stated rather than discovered:

- **Every apply reads 1Password.** chezmoi caches the read for the duration of a run and
  the item holds all fields, so the cost is at most one unlock per apply. Rendering once
  into an unmanaged file would avoid it and is deliberately *not* done — that is the
  recorded intermediate state the convergence invariant bans.
- **The failure mode, no longer a quiet one.** If the render is skipped, the client-issued
  identity is absent — and because nothing defaults, the affected repository stops at its
  first commit instead of signing as personal. The **dynamic check in the drift report**
  stays: it turns that stop into an explanation, ahead of the moment it would otherwise be
  met.

**Keys: one per account, doing both jobs.** Each key is a single `ssh-ed25519` key used
for authentication *and* signing. There are two, not three: personal and company work run
through one github.com account and share its key, differing by address alone, while the
client-issued identity has its own account and its own. ADR 0008 said *per identity*, which
was written before the two came apart; the argument it rests on is unchanged and now cuts
the same way twice. Splitting authentication from signing was rejected: both keys would live
in the same vault behind the same unlock, so the separation is nominal while the cost — two
keys and three registrations at the one manual point of the rebuild — is real. A separate
key for the company identity was rejected for the same reason, with the account shared as
well.

**The agent is told which vaults to look in.** Its default covers the built-in vaults only
— Personal, Private and Employee — and the keys for client project servers live in a shared
vault, which the default never offers. `~/.config/1Password/ssh/agent.toml` names the two
vaults, and nothing else: the file is an allowlist rather than an addition, so the built-in
vault is named there too, and naming *vaults* instead of *items* is what keeps client names
out of a public tree (ADR 0003). The ordering the file can also express is not used, because
the live keys stay under the six-attempt limit an SSH server imposes by default — and the
order of items in a vault is vault state, which this repository does not own.

**No retired key is carried anywhere** — no line in `allowed_signers`, no registration
left on the GitHub account. This is safe because nothing is lost: GitHub records a
verification when it performs it and never revisits it, so existing commits keep their
badge regardless of the key's later state; and an SSH signature embeds the signer's public
key, so a retired `allowed_signers` line is reconstructible from any commit it signed. The
cost, plainly: locally, pre-rotation commits report an unknown signer. On GitHub they stay
Verified. Because the file holds exactly the live identities, no pruning rule has to exist.

**Public keys are files** — `id_personal.pub` beside `id_work.pub` — with both
`user.signingkey` and the `allowed_signers` line deriving from the file rather than
transcribing the blob twice.

**Rotation is not part of the rebuild and not on a schedule.** The keys never touch disk;
they live in 1Password and are offered only through the agent, so there is no exposure
that grows with time. Rotation happens once, by hand, at any convenient moment. P0 item 6
says "register the public key on GitHub", which is true of whichever key exists. The
replacement is **verified before the old key goes** — an authentication that succeeds and a
signature that verifies — so one account holds two keys for as long as that takes. The
window is bounded by that verification and not by a date, and it is the only state in which
two keys exist for one account (ADR 0008).

**The key store is the company's, and that is a dependency on ownership.** There is one
1Password account, the company's, and its Employee vault holds the personal identity's key
as well as the client-issued one. This holds as long as the person owns the company. Deleting
a 1Password account destroys its Employee vault outright, so if that ownership ever ends the
key leaves the vault first — a deadline no phase can check, because the bootstrap runs while
the machine is still here, and one whose cost is bounded by how cheap rotation is (ADR 0011).

**The source remote is rewritten HTTPS → SSH after the agent is verified**, in P7's plain
`run_after_` script (not `run_onchange_`, whose content hash says nothing about the
remote's current value). It rewrites only a remote that is still the HTTPS form of a
GitHub clone, derives the SSH form from it rather than writing this repository's name out
a second time, and leaves the remote alone when the agent socket is missing — which is
what CI holds, where the gate reports the 1Password items rather than refusing them (§8).
The clone arrives over HTTPS because the repository is public; without the rewrite, the
first `chezmoi git push` from a rebuilt machine prompts for a password that no longer
exists.

**The repository is public**, and that is load-bearing: a private clone on a fresh Mac
needs a credential typed by hand, before `gh` and before 1Password exist, and it fails
*earlier than the gate that exists to catch preconditions* — as a bare HTTP error out of a
curl pipe. Going public deletes the one precondition the architecture cannot enforce, and
it is also what makes the macOS CI runners free. **Ordering is binding:** the work
identity is templated out of the tree **first**; the repository is flipped to public only
**after**.

---

## 7. `drift` — the check

One command, `~/.local/bin/drift`, from `home/dot_local/bin/executable_drift.tmpl`.

Drift is **never** measured Mac-to-Mac. Each machine is compared against this repository,
and the repository is the shared reference — two converged machines are identical by
construction.

It is called from three places: a human at a desk, the bootstrap's epilogue, and CI's
end-to-end assertion. That is why it is a real command on `$PATH` and not a script in the
repository: the one command whose entire value is being run on a whim must not require
`cd ~/.local/share/chezmoi` first. The name avoids `doctor`, which `chezmoi doctor`
already uses for an unrelated question.

**The bare name is knowingly taken.** Nothing in Homebrew ships a `drift` today — the
neighbours are `driftctl` and `driftwood`, each under its own full name — so the clash is
hypothetical. The direction that would bite is the other one: `~/.local/bin` comes first
on `PATH` (§6.3), so a `drift` arriving from upstream later would be shadowed by this one
silently, and the first symptom would be a tool that appears installed and does the wrong
thing. Named here so the annual review can answer it in one line rather than rediscover
it: if that ever happens, this command is the one that renames.

**Three sections; empty ones are omitted:**

| Section | Meaning | Action |
| --- | --- | --- |
| **Missing on the machine** | The repository declares it, the machine lacks it | Convergence failure — run the bootstrap again |
| **Not in the repository** | The machine has it, nothing declares it | A decision owed to the repository |
| **Diverged value** | A managed file or managed default disagrees | Re-apply, or adopt |

**Scope — swept for unmanaged additions:** Homebrew **leaves** only (dependencies are not
decisions), casks, `mas list` (which needs no root, unlike `mas install`), and
`/Applications` bundles from neither source — a dragged-in app is the one class the
Brewfile structurally cannot catch.

**Not swept:** `mise` runtimes, which `mise ls` already diffs against its own config, and
`chezmoi unmanaged` over `$HOME`, which is the swamp in its purest form.

**Checked for diverged values:** managed files (via `chezmoi status`/`verify`, which covers
them completely), **only the default keys the repository declares** — never `defaults read`
over a whole domain — the rendered Dock sequence, and whether the work identity actually
rendered.

The Dock reports as **one line** under *Diverged value*, followed by the expected and
actual tile sequences, compared against the **rendered** expected sequence (the
declaration minus uninstalled apps). So a missing cask is reported once, truthfully, by
the Brewfile sweep — not twice, the second time misleadingly as layout drift. The
consequence, stated rather than hidden: a Dock short a tile because its app never
installed reads *clean* here and *red* there.

**Report only. It never writes.** There is no `--adopt`: it would either produce
reason-less entries CI rejects, or prompt for eighteen reasons interactively. Adoption is
a judgement pass — that is the annual review's whole job. No `--json` either: no second
consumer exists.

**When:** on demand, plus the tail of every bootstrap — the same invocation, no `--brief`
flag, because on a fresh machine the *Not in the repository* section is empty and
therefore not printed. **No schedule and no login hook:** a recurring prompt on a machine
reviewed once a year trains you to dismiss it.

**Scripts are excluded from the managed-file check.** `chezmoi status` covers managed
files completely, but a `run_after_` script is pending by design on every run (§4), so
including scripts would report the bootstrap's own epilogue as drift, permanently.

**A sweep that could not run is said out loud**, under a closing *This report is
incomplete* — not a fourth section, because the three are findings and this is the
report's own reach. An inventory nobody could read and an empty inventory look identical
afterwards and mean opposite things, so an unanswered question takes its comparison out of
the run rather than reporting the whole inventory as missing. It exits 1 on its own: a
report that did not look cannot say the machine is clean.

**It carries no `# Phase:` header**, unlike every script under `.chezmoiscripts/` (§4). It
is a command rather than a phase — there is no order for a precondition to justify — so
the field it would carry has nothing to say, and CI's header check reads the phase scripts
only.

**Exit 0 clean, 1 on any drift**, matching `chezmoi verify`.

---

## 8. What CI verifies (ADR 0004)

Two tiers.

**Lint tier — `macos-26`, every push and pull request.** `chezmoi apply --dry-run`; shellcheck over
**rendered** scripts and the rendered `drift` (sources are `.tmpl`, so the tier renders
them with `chezmoi execute-template` first — a template that fails to render is caught a
step earlier than one that renders to broken shell); `tests/drift.sh`, which runs that
rendered command against stubbed inventories; `tests/identity.sh`, which asks the real git,
against the rendered `~/.gitconfig`, which identity each shape of remote selects — a pattern
that matches nothing is otherwise silent until a commit is refused somewhere else entirely
(§6.5); the Brewfile reason-comment presence check;
the script-header presence check; and the Dock-entry reference check. Both tiers
run on macOS for the same reason: the source tree is templated for darwin, so a Linux
runner would render the branch this repository never applies and lint the wrong shell.

**End-to-end tier — `macos-26`, on pull requests and once a week.** Runs the real
bootstrap, then runs `drift`, and **the exit code is the assertion**. A thin `bats` layer
holds only what a state check structurally cannot express — chiefly that a second apply
changes nothing, which is the convergence invariant.

**The drift report is the oracle, not a bats expectation file.** A second set of
expectations beside it would be the two-lists-one-truth failure again, inside the very
tool built to detect it. `tests/drift.sh` is not that second list: it stubs the machine
and asks which section an entry lands in and how a bundle's provenance is decided, and the
entries it bends are *read out of* the Brewfile rather than named, so editing the inventory
cannot quietly turn a check into a no-op. Reusing it pays twice: the detector, which
otherwise runs a handful of times a year, becomes continuously tested.

**The gate reads `CI`.** Under it, the 1Password preconditions degrade from refusing to
reporting; everything else still refuses. Deriving CI from `op`'s *absence* was the
tempting version and does not survive: a genuinely fresh Mac has no `op` either,
and that machine must be refused. A signal that cannot tell the two apart waves through
precisely the case the gate exists for. `CI` is set by the runner and never written by
this repository, so it is environmental fact, not the opt-in flag rule 6 rejects.

**The runner is not fought.** `macos-26` arrives with Homebrew, Command Line Tools and
runtimes preinstalled, and the image changes monthly. Stripping it is declined — that
would make the runner a second system. Uninstalling just Homebrew is declined too: it is
the most widely exercised step in the whole bootstrap and the least plausible place for a
rebuild to die.

**Red pipelines mean work.** The lint tier and the pull-request end-to-end run are
required checks on `main`. The scheduled run blocks nothing by construction, so on failure
it **opens or updates an issue** in this repository's triage flow. Scheduling it is an
agreement to treat its failures as work; otherwise it is coverage in appearance only.

The weekly run is the tier that serves the mandate. It is the only thing that catches
**upstream rot** — a cask renamed, a formula dropped, an App Store ID changed — which is
what makes a rebuild fail a year after the last commit. A recurring prompt at your desk
trains you to dismiss it; a failing Action is not at your desk.

**Knowingly unverified**, handled as manual gates rather than tested away: anything behind
an Apple ID, so `mas` end to end; 1Password's first authentication and its agent socket;
FileVault; bare-metal state, since the runner is warm, so the tier proves convergence
rather than a rebuild from nothing; the work identity's *populated* branch and the work
group's `brew bundle --file` invocation with it, since CI has no vault and the same guard
covers both; and anything bound to the machine's own hardware.

A green pipeline proves the automated path works. It cannot prove the human path works.
The closing report is the only thing that inspects the human path's result.

---

## 9. The annual review

The review happens **at the desk, before the wipe** — that is the entire point. It is run
against this document and the declarations it describes.

1. **Run `drift`.** Section 2, *Not in the repository*, is the year's agenda: everything
   the machine acquired that nothing declares. Each entry is a decision owed — adopt it
   with a reason, or let the wipe take it.
2. **Re-derive usage from the machine, not from the file.** Nothing here stores a
   "last confirmed" date (rule 4). Read staleness off the live machine instead:

   ```sh
   brew leaves                                  # formulae that are decisions, not dependencies
   brew list --cask
   mas list
   mdls -name kMDItemLastUsedDate /Applications/<App>.app
   ```

   plus shell history for the CLI entries. This is exactly how the inventory was judged
   the first time, and it is deliberately **not** a command in this repository: it has one
   consumer, once a year, and its output is a reading rather than a pass/fail. Building a
   tool for it would be the speculative generality rule 5 forbids — and folding it into
   `drift` would break that command's exit-code contract, which CI depends on as an
   oracle.
3. **Apply the bar** (§6.1): demonstrated use, with bootstrap dependencies and background
   applications as the only two exemptions — both written into the entry's own reason so
   the exemption is not re-litigated.
4. **Re-ask the one open sourcing question** (§6.1): has a Homebrew cask appeared for any
   of the four App Store entries? That is the only per-app question the review ever asks
   about sourcing.
5. **Check the upstream health of the load-bearing tools** — chezmoi and mise above all.
   Two things are on watch: `mise` has grown its own dotfiles feature, which would collapse
   two tools into one if it matures, and chezmoi's bus factor is real but unquantified.
6. **Curate the claude.ai account** (§6.3). It is the restore mechanism for the entire
   agent-tooling surface, and this repository checks nothing about it.
7. **Then wipe**, and run the command in §1.

---

## 10. Known gaps

Stated rather than discovered later.

- **The GitHub account is not a checked surface.** The account carries several registered
  authentication keys where the machine holds one; they were pruned by hand and the check
  was deliberately not automated, because it needs a `gh` token scope the bootstrap avoids
  depending on. The claude.ai account (§6.3) is unchecked for the same reason and matters
  more, since ADR 0010 makes it load-bearing.
- **A private marketplace on a non-GitHub host** has no demonstrated route onto the
  account and would be the first candidate for a named exception to ADR 0010. There is
  none today.
- **The work group is exercised at one desk or not at all.** CI renders the op-less
  branch, so neither the work identity's populated templates nor the group's second
  `brew bundle --file` invocation is ever run by a machine other than a company Mac.
  This is one gap with one cause — the `op` guard of §6.1 and §6.5 — widened
  from the identity to its tooling, not a second one.
- **Onboarding a third machine, or handing this to someone else**, is not a goal. The
  document is written for two identical machines and one reader.
- **Restoring repositories and working data** (`~/Development`, clones, project files) is
  out of scope: that is a backup concern, not a bootstrap concern. Several decisions here
  lean on it — Obsidian's vaults and project-scoped agent plugins both live inside that
  zone.

---

## Architecture decision records

| ADR | Title |
| --- | --- |
| [0001](docs/adr/0001-chezmoi-driven-convergent-bootstrap.md) | A chezmoi-driven, convergent bootstrap |
| [0002](docs/adr/0002-drift-detected-against-repo-declarations.md) | Drift is detected against the repository's own declarations |
| [0003](docs/adr/0003-secrets-absent-identity-templated.md) | Secrets are absent from the repository; the work identity is a 1Password template |
| [0004](docs/adr/0004-ci-verifies-the-bootstrap-in-two-tiers.md) | CI verifies the bootstrap in two tiers |
| [0005](docs/adr/0005-chezmoi-source-is-a-subtree.md) | The chezmoi source is a subtree, not the repository root |
| [0006](docs/adr/0006-managed-configuration-is-hand-authored-plain-text.md) | Managed configuration is hand-authored plain text, and nothing else |
| [0007](docs/adr/0007-an-application-comes-from-the-app-store-only-when-it-has-no-cask.md) | An application comes from the App Store only when it has no Homebrew cask |
| [0008](docs/adr/0008-one-key-per-identity-nothing-retired-is-carried.md) | One key per identity, for both roles; no retired key is carried |
| [0009](docs/adr/0009-the-dock-is-reconciled-not-rebuilt.md) | The Dock is reconciled, not rebuilt |
| [0010](docs/adr/0010-agent-tooling-is-restored-from-the-account.md) | Agent tooling is restored from the account, not declared |
| [0011](docs/adr/0011-no-default-identity-keys-belong-to-accounts.md) | There is no default identity; keys belong to accounts, addresses to engagements |
