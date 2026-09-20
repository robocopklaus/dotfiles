# One key per identity, for both roles; no retired key is carried

Each identity has exactly **one** SSH key, and that key does both jobs: authentication to the Git host, and commit and tag signing. This is already what the work identity does. The personal identity is brought into line, and its `ssh-rsa` 2048-bit key — created years ago, the last RSA key left in the agent — is replaced by an `ssh-ed25519` one.

Both public keys are **files**: `id_personal.pub` beside `id_work.pub`. `user.signingkey` points at the file rather than inlining the key blob, so the public key has one copy on disk and `allowed_signers` derives from the same source instead of holding a second transcription of it.

**No retired key is carried anywhere** — not as a line in `allowed_signers`, and not as a registration on the GitHub account. When a key is replaced, both entries go in the same act that adds the new one.

Rotation is not a scheduled event. The keys never touch disk: they live in 1Password and are offered only through the agent, so there is no exposure that grows with time — which is the only thing a rotation schedule would buy. The replacement of the RSA key happens once, by hand, at any convenient moment. It is deliberately **not** part of the rebuild: the preflight item that registers a public key on GitHub already says "register the key", which is true of whichever key exists, so the specification describes no rotation procedure at all.

## Considered options

**Separate keys for authentication and for signing.** Rejected. It would mean a leaked authentication key could not forge commits, but both keys would sit in the same vault behind the same unlock, so the separation is nominal. The cost is not: it doubles the key registration in preflight — two keys, three registrations on GitHub — at the one point in the rebuild where the work is manual.

**Keeping the RSA key.** Rejected, and the argument for it turned out to be empty. The one thing that spoke for it was history: signatures verify against the key that made them. But GitHub records verification at the time it is performed and does not revisit it — *"previously verified commits retain their verified status… GitHub will not re-verify previously signed commits or retroactively adjust their verification status in response to changes in the key's state."* Rotating therefore costs nothing that is publicly visible, and the replacement rides along on a manual step that happens anyway.

**Accumulating retired lines in `allowed_signers`.** Rejected. The file would grow one line per rotation under a rule that never removes anything, and the question of what prunes it would have to be answered forever. Nothing is lost by dropping the line: an SSH signature embeds the signer's public key, so the retired key can be read back out of any commit it signed and the line reconstructed on demand.

**Making the annual wipe a rotation date.** Rejected. It would add a standing manual preflight item, every year, against a threat that the storage model does not produce.

## Consequences

Locally, `git log --show-signature` reports pre-rotation commits as signed by an unknown key, because the retired line is gone. On GitHub the badge is unaffected. This is reversible at any time from the signature blob itself, which is why the line is not kept on the chance that it is wanted.

The preflight item that registers a public key is unchanged, and the specification stays free of a rotation procedure — the decision here is made once and does not re-enter the bootstrap.

Keys registered on the GitHub account beyond the one the machine holds are **not** caught by the drift report. Detecting them needs an API token scope that the bootstrap deliberately does not depend on, and adding it would re-introduce the `gh` sign-in that was ruled out of the gate. Pruning the account is a manual act at review time, not an automated check.

## Addendum: retirement is not simultaneous

*"When a key is replaced, both entries go in the same act that adds the new one"* cannot be
read literally, and following it literally would be wrong. A new key is registered before it
is known to work, and removing the old one first means testing the replacement with nothing
to fall back to. There is therefore a **verification window** in which one account holds two
keys.

The window is bounded by an act rather than by a date: the retired key goes as soon as the
replacement is verified in **both** of its roles — an authentication that succeeds against
the host, and a signature that verifies — and the two registrations a single key needs on
GitHub are both in place. It is the only state in which two keys exist for one account.

Nothing detects it, by the same argument that closes this ADR: keys registered on the
account are outside the drift report, because catching them needs a token scope the
bootstrap does not take. The window is therefore recorded here instead of checked, so that a
second key found on an account reads as a step in progress rather than as the defect this
ADR otherwise forbids.
