# What's new

Short operator announcements. You see this at the start of a session only when
it has changed since you last read it — if nothing is new, it stays out of your
way.

---


## 2026-09-24 — Saving to the drop box now sends two files, under the model's noctua-dev id

**What changed.** A drop-box submission is now the model in two formats with one
id: `<id>.yaml` (gocam-py YAML) and `<id>.ttl` (minerva's own Turtle), where
`<id>` is the id noctua-dev gave the model. The TTL is what enters production;
the YAML is what reviewers and CI read. Claude does the exports and the PR.

**What it means for you.**
- **Build on noctua-dev.** A model has to exist there and be **stored** before
  it can be saved. Ask Claude to store it; unstored work is lost when the dev
  server restarts. The model's state is yours to set; `development` is fine.
- **Parking work in progress?** Say so, and Claude opens the PR as a *draft*:
  saved and safe, but not up for merge until you say it is final. The model's
  state stays whatever you set it to in Noctua.
- **Edits go through dev.** If you change a model after submitting, tell Claude;
  it re-exports both files and updates the PR. Hand-edited files are refused.
- **Your merged models now reach production.** Twelve drop-box models were
  copied into production Noctua at the 2026-09-24 maintenance outage, keeping
  their ids. Future batches follow at the second and fourth Thursday outages;
  the drop box's `PROMOTIONS.md` lists each one.
- **CI is stricter in one useful way:** it now runs production's own QC checks
  on the TTL, so orphaned evidence and duplicated evidence axioms are caught
  before merge instead of after.

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
