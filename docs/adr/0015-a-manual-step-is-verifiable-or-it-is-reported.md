# A manual step is either verifiable and refused on, or unverifiable and reported

The rebuild depends on work no script performs: signing in to an Apple Account, unlocking 1Password and turning on its two developer toggles, registering a public key on GitHub. Each such step falls into exactly one of two categories, and the category decides where it is handled.

**Verifiable.** The run can ask the machine whether it is true. Then it is a precondition the gate refuses on, with a remedy naming one way to fix it. Administrator rights, the architecture, the macOS version, the network, the Command Line Tools, the 1Password app and `op`, the SSH agent socket, the CLI integration (ADR 0014).

**Not verifiable.** The run cannot ask. Then it can only ever be a tolerant failure plus a line in the closing report. Whether an Apple Account is signed in, whether the App Store is signed in, whether the public key is registered on GitHub under *both* SSH keys and SSH signing keys.

**There is no third category, and in particular there is no prompt.** A self-attested `have you signed in? [y/N]` is a prompt wearing a gate's clothes: it blocks the run while verifying nothing, and it trains the person to answer yes. A gate that refuses on things it cannot check is a gate you learn to bypass.

## Considered options

**Ask the human to confirm the unverifiable steps.** Rejected. The answer carries no information, and the cost is a second interactive moment in a run that spends its entire interactive budget on one `sudo -v`.

**Refuse on everything, verifiable or not.** Impossible for the unverifiable half, and harmful where it is merely inconvenient: FileVault is deliberately not a gate item, because the run neither fails nor produces a broken machine without it.

**Report everything, refuse on nothing.** This is roughly what the prior setup did, and it is why a machine could complete a bootstrap and be quietly broken. A precondition the run can check is one it should stop on, before files are written rather than after.

## Consequences

**The closing report exists because this rule does.** It is where the unverifiable half lands, re-derived from the world on every run rather than replayed from anything recorded.

**A step moves between the two categories when the world changes, not when convenience suggests it.** The CLI integration moved from reported to refused the moment a check was found that answers the right question without unlocking anything (ADR 0014).

**FileVault stays out.** The gate's mandate is narrow: things without which this run fails or produces a broken machine.
