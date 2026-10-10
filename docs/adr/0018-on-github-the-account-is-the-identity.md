# On github.com the account is the identity

Two identities commit from this machine, not three. Every repository on `github.com` — whoever owns it, whoever the work is for — commits as the **personal** identity: the robocopklaus account, its key, and its no-reply address. The **client-issued** identity is unchanged, on its client's own hosts. The **company** identity is gone.

This supersedes ADR 0011 in one respect: on github.com, the address follows the account, not the engagement. Everything else in ADR 0011 stands, above all the refusal: a remote on any host no identity declares still does not commit.

**The address the company identity carried was never one a commit could use.** `fabian@21st.digital` is the account's primary address, and the account keeps it private. GitHub's answer to a private address is the no-reply one: it is what the account expects on everything pushed, and a commit carrying the private address is what failed, repeatedly, at the point of committing and pushing work in the company's organisations. The company identity separated engagements by an address the account had already chosen not to publish.

**And the organisation boundary is not one the address could follow.** 21st digital is a github.com organisation the account is a member of; a client is another organisation the same account is invited into. Every owner the work lands under is reached through the one account. Matching company organisations by name already left client organisations on github.com to the refusal, and matching those by name would write the client relationship into a public tree — the leak ADR 0003 exists to prevent. With one identity for the whole host, nothing is named: the pattern is `github.com/*`, in both remote spellings.

## Considered options

**Keep the company identity, with the no-reply address.** Rejected. It would differ from the personal identity in nothing — account, key and address all the same — and a second file stating the same fact is a second list.

**Make the company address public on the account.** Rejected. It reverses a privacy choice made on the account to serve a convention in this repository, and it would still leave client organisations on github.com to be matched by name.

**Match client organisations on github.com through the 1Password item, behind the `op` guard.** Not needed: with the address following the account, there is nothing to tell a client organisation apart from any other owner on the host.

## Consequences

**ADR 0011's objection to a personal default is answered, not overruled.** It held that a personal default "signs paid work with a private address". The no-reply address is the account's address, not a private one, and it is the only one the account publishes. Who the work was for is recorded by where the repository lives, not by the commit's address.

**`allowed_signers` holds two lines against two keys.** One per account.

**The refusal moves off github.com.** A repository with no remote, or a remote on a host no identity declares, still refuses its first commit. A github.com repository no longer can.
