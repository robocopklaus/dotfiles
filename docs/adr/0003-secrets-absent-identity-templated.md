# Secrets are absent from the repository; the work identity is a 1Password template

1Password remains the root of the machine's trust: the SSH agent for authentication, `op-ssh-sign` for commit and tag signing, and the store for every token. The repository itself declares **no secret**. Tokens are fetched by hand the first time a tool needs one, exactly as before.

One thing does come out of 1Password at apply time: the **work identity** — the client's Git host, the account name and address, and its signing key. It is rendered from a single 1Password item into the four files that would otherwise carry it in a public tree.

The work identity is treated as one indivisible item. Nothing about it is cryptographically secret — both signing keys are public keys and the host is a public DNS name — so the thing being kept out of the tree is the client relationship, and half-evicting it reveals the same fact for none of the benefit. Its filenames leak too, so the client name disappears from those as well: `config-work`, `id_work.pub`.

A machine without `op` renders the personal identity only, and applies cleanly. That is what keeps the bootstrap testable: CI runs the real thing, and a mechanism that only works at one desk is untested by construction. The refusal lives in the preflight gate, which already verifies 1Password — the template layer does not refuse a second time.

The source repository is cloned over HTTPS, because it is public and a fresh machine has no credential. Once the agent is verified, a phase rewrites the source remote to SSH, so the first push after a rebuild does not prompt for a password that no longer exists.

## Considered options

**Templating tokens out of 1Password so a rebuilt machine is fully logged in.** Rejected. Four months of evidence say no secret was ever needed to *reach* a working machine, and the prior setup — public for years — contains not one `op://` reference. The cost is structural: every `chezmoi apply`, on every machine, would then depend on an unlocked vault. Convenience at that price buys a bootstrap that can fail for a reason unrelated to anything it was asked to do.

**An unmanaged local include for the work identity.** The `includeIf` points at a file chezmoi does not manage, written once by hand from a 1Password note; Git silently ignores a missing include path, so the public tree stays valid and CI is untouched. Rejected, and it is the close call. It is cheaper to build, but the host pattern is itself the giveaway and would have to move too, making the whole second config unmanaged — which re-introduces precisely the "pull it back when you miss it" manual step this rebuild exists to eliminate.

**chezmoi age-encrypted files, key in 1Password.** Rejected. It keeps the files managed and the diff reviewable as ciphertext, but it adds a second secret mechanism beside `op` in order to protect data that is not secret.

**Abandoning 1Password for on-disk keys and `ssh-agent`.** Rejected. It would delete three preflight items and the agent-socket check, but it trades a *verifiable* precondition for an unverifiable secret-restore problem, and puts private keys on disk to do it.

**Hard-failing the render when no vault is present, and giving CI a stub `op`.** Rejected. A fake `op` in CI means the templates CI proves are not the templates that run.

## Consequences

The guard is derived from the machine — whether `op` is on the path — not from a flag. A flag is a second truth that can be set wrongly; the preflight gate already guarantees `op` on a real Mac, and its absence in CI is a fact, not a configuration.

Every apply re-renders the templates, so an apply reads 1Password. chezmoi caches the read for the run, so the cost is at most one unlock per apply, and the item is shaped to hold all the fields so it stays one read. Rendering once into an unmanaged file would avoid it and is not done: that is recorded intermediate state, which the convergence invariant bans.

The 1Password item's name and vault appear in a public repository as a pointer. They must therefore not name the client either.

There is a hard ordering constraint on implementation, inherited from the preflight decision: the work identity is templated out of the tree **first**, and the repository is flipped to public only after.

`gh auth login` is not a gate item and not in the closing report's static tail — nothing in the bootstrap depends on it, and the tail is reserved for sign-ins that other things need. It surfaces the first time `gh` is used.

The drift report gains the work identity as a dynamic check: on a machine where it failed to render, the files are silently personal-only, which is the one failure mode this design can produce quietly.
