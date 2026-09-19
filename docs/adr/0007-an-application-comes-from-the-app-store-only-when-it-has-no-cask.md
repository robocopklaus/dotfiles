# An application comes from the App Store only when it has no Homebrew cask

Two clauses decide where a managed application comes from, applied in order. First, if the application restores itself from an account, the repository declares nothing. Second, of what remains, an application comes from the App Store only when no Homebrew cask exists for it. The App Store is a fallback, never a preference.

The prior setup had no rule, only six App Store entries that had accumulated because that is where they were first found. The question the January review actually asks is not "is this app still used" — the content review answers that — but "why is this one installed differently from the others", and an inventory without a sourcing rule has no answer.

The second clause costs nothing to apply because it is a fact, not a judgement: `brew search --cask` either finds the application or it does not. Measured against the base inventory, it leaves the App Store population at exactly four — Pages, Numbers, GCal for Google Calendar and 1Password for Safari — none of which has a cask, and no fifth entry is reachable by any future judgement call. Four applications in the base are genuinely available from both sources and all four are already taken from Homebrew: Slack, WhatsApp, Telegram and Clockify.

Three reasons stack behind preferring Homebrew where both exist, and the third is the one that matters here:

- App Store builds are sandboxed, and the resulting feature reduction is real rather than theoretical.
- App Store updates lag the vendor's own release channel.
- **Every App Store entry widens the Apple ID gap.** `mas install` requires root, and it can install nothing unless the Apple ID is already signed in — the one precondition ADR 0003's gate cannot verify, which ADR 0004 must in turn degrade under CI. Each entry moved off `mas` narrows a failure branch that exists in two places; each entry added widens it.

## The first clause is the same criterion as ADR 0006

A Chrome extension is installed by signing into Chrome with the Google account; sync does the rest. An App Store purchase sits inertly in Purchased history and installs itself on no machine, ever. The repository therefore declares 1Password for Safari and says nothing about the Chrome extension of the same product — which reads as an inconsistency only until the criterion is named. It is *account-restored* in ADR 0006's sense, recorded in the specification's table with that word, and the repository does nothing about it because there is nothing to do.

This is the whole of the first clause: **the repository declares what does not come back by itself.** ADR 0006 reached it for configuration files; this decision reaches it for applications, and it is the same sentence both times.

Signing into Chrome is consequently not a preflight gate. ADR 0003's static tail admits only the sign-ins that other things depend on, and no phase of the bootstrap depends on a browser extension.

## The run has exactly one interactive moment

`mas install` requires root, so `sudo -v` fires at the top of the preflight gate, before any file is written, with a keep-alive for the remainder of the run.

This is in tension with ADR 0001's rule that nothing ever pauses, and the tension is stated rather than argued away. That rule was written against the 3600-second Command Line Tools poll: an unbounded wait on external state, which is why it became a precondition instead. A password prompt is bounded, immediate, and answerable without leaving the desk. The rebuild is not input-free, the specification says so plainly, and it names the one place it happens. The mandate this map serves is that the *review* happens at the desk before the wipe — not that the run is literally unattended.

## The drift report enumerates the App Store

ADR 0002's report gains the App Store as a surface. `mas list` needs no root, so enumerating costs nothing and requires no gate.

The blind spot this closes is not hypothetical. Keynote and Super Agent were both cut by the content review and are both still installed, with App Store receipts and no launch record. A report that reads only Homebrew cannot see them, and a rebuild would drop them in silence — which is precisely the review-through-the-wipe loop the content review set out to end. They appear today in the report's second section, as installed and not in the repository.

The first section matters equally: a declared App Store entry that is not installed is how a tolerant `mas` failure becomes visible. Without it, the only failure the ungateable precondition can produce is one nothing ever reports.

## Considered options

**Cut `mas` entirely; install the four by hand from Purchased once a year.** This was close, and its argument is the honest one: the App Store sign-in is ungateable regardless, so `mas` automates the cheap half of a flow whose expensive half stays manual, buying four clicks a year in exchange for a permanent tolerant-failure branch in the preflight gate *and* a degradation clause in CI. It was rejected because dropping the four from the repository leaves an unmanaged tail, and the content review's third criterion is explicit that the Brewfile becomes the full truth of the machine. A tail means the wipe still silently deletes things.

**Declare the four but never install them** — the report names what is missing, the human installs from Purchased. Rejected on mechanism, not on merit. A Brewfile `mas` line *is* an executable declaration, and ADR 0005 inlines the single Brewfile into `brew bundle`. Making those lines inert requires a second declaration surface, which is the two-lists-one-truth arrangement this effort ruled out before charting began.

**Add a licence-tied-to-Apple-ID exception** — a paid application whose licence lives in the Apple ID comes from the App Store even where a cask exists, because the cask would install an unlicensed copy. Rejected: there are zero such entries. Generality arrives with the second real consumer, and this clause has no first one. An unexercised exception is a clause the January review reads, cannot map to anything on the machine, and hesitates over — the exact ballast this effort exists to prevent. The failure if the case ever arrives is loud and immediate, the application launches unlicensed and is noticed on first use, and costs one line to fix then. A rule with one clause is worth more than a rule with two, one of which has never fired.

## Consequences

The App Store population is now closed by construction rather than by review. No future entry can reach it through a preference, so the annual review never re-asks "should this one have come from the App Store" — it asks only whether a cask has appeared since, which is a single command.

`mas` stays in the Brewfile as a bootstrap dependency, unchanged by this decision.

The four entries remain the only part of the run that depends on a precondition no gate can verify. This decision narrows that dependency to its minimum and makes its failures visible in the report; it does not remove it, and no arrangement short of cutting the four can.
