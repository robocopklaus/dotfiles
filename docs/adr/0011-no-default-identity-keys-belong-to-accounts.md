# There is no default identity; keys belong to accounts, addresses to engagements

Three identities commit from this machine, not two: the **personal** one, the **company** one (21st digital, under which client work on github.com is done), and the **client-issued** one, whose account, hosts and key belong to a client rather than to the person or the company.

They are selected by two different rules, because two different things are being decided.

**Key material belongs to the account that verifies it.** A signing key is registered on one account, and that account is what makes a signature verify. Personal and company work both run through a single github.com account, so they share one key; the client-issued identity has its own account on its client's own hosts, so it has its own. That is a correction to ADR 0008's phrasing — *one key per identity* — which was written when "identity" and "account" still looked like the same thing. The rule is **one key per account**, and ADR 0008's argument is unchanged: a second key behind the same unlock on the same account is a nominal separation bought at a real cost.

**The address belongs to the engagement.** `user.email` — and, where the account differs, `user.signingkey` — is what says who the work was done for. It is selected per repository by `includeIf "hasconfig:remote.*.url:…"`, keyed on the remote, because the remote is the fact that decides which account will verify the signature. A directory convention was rejected: it is a promise about where files are put, and it is broken the first time a repository is cloned somewhere else.

**And there is no default.** `~/.gitconfig` carries only what every identity shares — `user.name`, and the signing setup — plus `user.useConfigOnly = true`. It carries no `user.email`. A repository that no `includeIf` matches does not get a fallback identity; it **refuses to commit** until one is named.

That is the whole decision, and the reason is the direction of the failure. Every default is wrong somewhere:

- A **personal** default signs paid work with a private address, and the mistake is invisible until someone reads the history of a client repository.
- A **company** default signs private side projects with a company address, and it writes an employer into the root of a repository that is personal property and outlives the employment.

Both are silent. Neither announces itself at the moment it is made. Refusal is loud, it happens at the first commit rather than at the hundredth, and it costs one line of configuration to resolve. This repository already reasons this way about denylists and allowlists (ADR 0005) and about checkpoints (ADR 0001): a mechanism that fails by doing something plausible is worse than one that fails by stopping.

**One consequence names itself.** Enumerating which repositories are personal and which are company work would mean writing client organisation names into a public tree — the same client relationship ADR 0003 templates out. With no default, nothing has to be enumerated in order to *avoid* one. Only the identities themselves are named, and the client-bearing half of that is already behind the 1Password guard.

**The repository stays in the personal account.** It manages a person's working environment — shell, editor, keyboard, Dock — and follows that person across employers. The machines are the company's; the way of working is not. What belongs to the company or its clients is exactly what already sits behind the `op` guard and never enters the tree.

## Considered options

**Keep two identities, personal and "work".** Rejected as a description of the fleet. The identity called "work" is an external-contractor account issued by one client, on that client's hosts; it does not survive that engagement, and it has never covered company work done on github.com — which today is signed with a private no-reply address for lack of any other option.

**A company default, with personal repositories as the exception.** Seriously considered, and it is the better of the two defaults: the exception list is finite, known and owned by the person, while the set of client organisations grows without their involvement. It was rejected on ownership. It makes an employer the standing assumption of a repository held in a personal account, and the day that employment ends, the correction has to be made everywhere at once.

**A personal default, with company and client work switched on by pattern.** Rejected for the leak. To switch company work on, the client organisations have to be named, in a tree that is public — which is precisely the fact ADR 0003 exists to keep out of it.

**Giving the company identity its own key.** Rejected. It would sit on the same github.com account as the personal key, behind the same 1Password unlock. GitHub verifies against the account, so the second key changes nothing a reader can see, and it costs another registration at the one manual point of the rebuild.

**A directory convention (`includeIf "gitdir:…"`).** Rejected on evidence. It describes where repositories are supposed to live, not who owns them, and the working tree it would key off has no such convention to begin with.

## Consequences

**A repository in new territory stops at the first commit** with git's own error, and stays stopped until its identity is named. That is friction, and it is the price of the decision rather than an oversight. It is bounded: a pattern covers an entire account or organisation, so it is paid once per relationship, not once per repository.

**`allowed_signers` holds three lines against two keys.** Personal and company differ by address alone, so the same public key appears twice under two addresses. The file continues to hold exactly the live identities and nothing retired (ADR 0008).

**The quiet failure mode that the drift check was built for shrinks.** A skipped render used to mean client work was silently signed as personal; with no default it means client work does not commit. The check stays — it turns a stop into an explanation — but it is no longer the only thing standing between a missing render and a mislabelled history.

**Matching must cover an account's full surface.** One issuing account may answer on several hosts and in both SSH and HTTPS remote forms. A pattern that covers one host, or only the SSH spelling, leaves the rest to the refusal — which is safe, but it is friction that was not chosen. The patterns are derived in the template from the hosts an identity declares, rather than written out by hand.
