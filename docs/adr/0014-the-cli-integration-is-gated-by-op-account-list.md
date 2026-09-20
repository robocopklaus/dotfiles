# The 1Password CLI integration is gated by `op account list`, not `op whoami`

The 1Password CLI integration is the setting that hands the account to `op`. Without it `op` holds no account at all. The gate refuses on it, and asks the question with `op account list`.

The toggle is a necessary condition, not the only one: an empty account list also means the app's data could not be read at all, which ADR 0016 splits out into a check of its own ahead of this one.

**Why it is gated at all.** Left ungated, the toggle does not fail the run cleanly. P3 renders the work identity through `op`, and `op` with no account does not error — it *asks*, in the terminal, for a sign-in address, an email address, a secret key and a password. That is a second interactive moment in a run that promises one, collecting a secret this repository is built never to handle; and when nobody answers it, the run dies on an authorization timeout naming the template rather than the toggle.

**Why not `op whoami`.** It asks whether a *session* is open, and the run does not need one — the session is created at first use, when P3 renders the work identity and the app authenticates. A machine that is entirely correct, with the integration on and the vault simply not unlocked yet, fails `op whoami`. Gating on it would refuse the machine this repository is built to produce.

The claim that once justified leaving the toggle ungated — that verifying it costs an interactive prompt — was never true. `op whoami` prompts for nothing: with no account it answers `no account found for filter`, and with an account but no live session it answers `account is not signed in`, both as errors.

**Why `op account list` is the right question.** It asks whether `op` has an account at all. It reads local metadata, returns at once and unlocks nothing. With the integration off it has nothing to list — the account is handed to `op` by the app rather than stored on disk, which is why a working machine's `~/.config/op/config` says `"accounts": null` while `op` still knows the account.

## Considered options

**`op whoami`.** Rejected above: it answers a question about sessions, and a session is not a precondition of the run.

**Leave it ungated and let P3 fail.** This was the prior state. It fails as an interactive prompt for a secret, then as a timeout naming the wrong thing. A verifiable manual step is a precondition the gate refuses on (ADR 0015), and this one is verifiable.

**Set `onepassword.prompt = false` and call that the fix.** It is declared in chezmoi's own configuration and it stays, but as the second net rather than the first: it turns the prompt into a failure, which is an improvement on a hang, but it still fails in P3 rather than at the gate and still names the template rather than the toggle. It is what covers the case where the gate degrades — under CI, where the 1Password items report rather than refuse and nothing may be prompted for.

## Consequences

**The toggle is a gate item, not something P3 discovers.** It is checked with the other trust-chain items, after the acquisition and before any file is written.

**The check costs nothing and unlocks nothing.** It reads local metadata; a locked vault passes it, which is the point.
