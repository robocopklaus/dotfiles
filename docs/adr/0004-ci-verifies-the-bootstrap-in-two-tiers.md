# CI verifies the bootstrap in two tiers

Two pipelines verify this repository. A **lint tier** runs on every push and pull request: `chezmoi apply --dry-run`, shellcheck over the *rendered* scripts, and the check that every managed entry carries a reason. An **end-to-end tier** runs the real bootstrap on a `macos-26` runner, on every pull request and once a week on a schedule.

The end-to-end tier's assertion is the drift command. It runs the bootstrap, then runs the drift report, and the report's exit code is the verdict. A thin bats layer sits beside it and holds only what a state check cannot express — chiefly that a second apply changes nothing.

This is the mechanism that makes the mode switch real. Reviewing at the desk and then running an unattended bootstrap is only defensible if the bootstrap is known to work; one live fire a year is not a feedback loop, and the weekly run is what turns "it worked last January" into "it worked last Tuesday".

## Considered options

**A Linux container tier between the two.** Rejected. It exists to be a cheap stand-in for an expensive macOS run, and on this public repository the macOS runner is free, so it has nothing left to buy. Worse, it could only run a variant of the bootstrap — skipping Homebrew, `defaults` and `mas` — so it would prove things about a configuration no machine ever runs, while rotting like any other second system.

**A bats suite carrying its own expectations** — binaries on the path, defaults values, managed files present. Rejected as the primary oracle. The drift report already enumerates the repository's declarations and checks the machine against them; a second set of expectations beside it is the "two lists, one truth" that ADR 0002 rejected for the drift detector itself, and it would rot in the same way. Reusing the report has a second payoff: the drift detector, which otherwise runs a handful of times a year, becomes continuously tested.

**Stripping the runner to approximate a fresh Mac.** Rejected. `macos-26` arrives with Homebrew, Command Line Tools and several runtimes preinstalled, and the image changes monthly; chasing it would make the runner the second system this ADR cut the Linux tier to avoid. Uninstalling only Homebrew was the narrower version and is also declined — installing Homebrew is the most widely exercised step in the whole bootstrap and the least plausible place for a rebuild to die.

**A `--skip-gate` flag so CI can pass the preflight gate.** Rejected, as ADR 0003 rejected its sibling: a flag is a second truth that can be set wrongly. **Letting CI enter at P1 and never run the gate** was rejected for the opposite reason — the gate would become the only phase CI never exercises, and it is among the most likely to be wrong.

**Deriving CI from the absence of `op`.** Rejected, though it reads like the natural extension of ADR 0003. A genuinely fresh Mac has no `op` either, and that machine must be refused; a signal that cannot tell the two apart would wave through exactly the case the gate exists for.

**Leaving the scheduled run advisory.** Rejected. A red run that blocks nothing is read once and then archived, which is coverage in appearance only — the failure mode the whole tier was built to avoid.

## Consequences

The preflight gate reads the `CI` environment variable, which the runner sets and nothing in this repository ever writes. Under it, the 1Password and Apple ID items degrade from refusing to reporting; every other precondition still refuses. This keeps the gate itself under test while leaving its behaviour on a real Mac unchanged.

shellcheck cannot lint the source tree. chezmoi sources are `run_onchange_*.tmpl`, so the lint tier renders them with `chezmoi execute-template` first and lints the output — which means a template that renders to broken shell is caught, and a template that fails to render is caught earlier still.

The lint tier and the pull-request end-to-end run are required checks on `main`. The scheduled run cannot block a merge, so on failure it opens or updates an issue in this repository's existing triage flow. Scheduling it is therefore an agreement to treat its failures as work.

**Knowingly left unverified**, and handled as manual gates instead:

- Anything behind an Apple ID, so `mas` end to end.
- 1Password's first authentication and its agent socket.
- FileVault.
- Bare-metal state — the runner is warm, so the end-to-end tier proves convergence, not a rebuild from nothing.
- The work identity's populated branch. CI has no vault, so it only ever renders the personal-only path; the templated client identity is exercised at one desk or not at all.
- Anything bound to the machine's own hardware.

A green pipeline therefore proves the automated path works. It cannot prove the human path works, and the closing report remains the only thing that inspects the human path's result.
