# What's new

Short operator announcements. You see this at the start of a session only when
it has changed since you last read it — if nothing is new, it stays out of your
way.

---

## Barista tokens: you use your own

There is no shared barista token. The first time you work with Noctua in a
session, Claude will walk you through getting your own token (an ORCID login on
the noctua-dev landing page) and save it to `~/.env`, so you only do this once.
Your own token is also the right thing for provenance — models you build are
attributed to your ORCID.

## noctua-dev is a proving ground, not a save

Models built on noctua-dev live in the server's memory until something triggers
a real save, so a server restart can take them. A successful read-back proves a
model exists *right now*, not that it will survive.

**Keep work you care about** by submitting it to the
[go-cam-drop-box](https://github.com/geneontology/go-cam-drop-box): just ask
Claude to *"save this to the drop box."* Once the PR is open your work is safe
and queued for GO Central review. A model does **not** need to be on noctua-dev
at all to be submitted.
