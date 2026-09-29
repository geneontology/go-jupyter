# What's new

Short operator announcements. You see this at the start of a session only when
it has changed since you last read it — if nothing is new, it stays out of your
way.

---

## 2026-09-29 — GitHub from the terminal: no second login

Signing in to the hub with GitHub now also signs in the `gh` command for your
account, so `git push` and `gh pr create` work without the copy-a-code login
step. At your next sign-in GitHub asks you once to approve repository access
for the hub; that approval is what makes this work. Your commit name and email
are set from your GitHub profile if you had none. `gh auth logout` ends the
terminal login at any time; `gh auth login` remains available as the fallback.
## 2026-09-29 — Sessions now run on Opus 5.5

Claude Code in your sessions now runs on Opus (currently Opus 5.5) as the main
model, with Sonnet as the fallback if Opus is briefly unavailable (you see a
notice when that happens). Until now the main model was Fable 5.1 with Opus as
fallback. `/model` in a session still lets you switch for that session.

---

## 2026-09-28 — Skills now come from geneontology/go-skills, checked out in your home

Your skills are no longer copies. `~/go-skills` is a git checkout of the shared
GO skills repository, and the skills Claude sees (`~/.claude/skills/*`) are links
into it. Two things follow:

- **You get new and updated skills automatically**, within minutes of a merge
  to go-skills, as long as your checkout is untouched. The first new one is
  `gene-review`, for reviewing a gene's GO annotations.
- **You can change a skill yourself.** Edit it in `~/go-skills` on a branch and
  ask Claude to open a pull request to go-skills. While you are editing, the
  automatic updates leave your checkout alone. Reviews are by the go-skills
  admins.

The GO-CAM skills you already had (amigo, noctua, gocam-best-practice,
pubmed-eutils, uniprot-database, annotate-function, save-to-drop-box) now come
from go-skills too. The copies you had are kept under
`~/.go-jupyter/refresh-backups/`; nothing of yours was deleted.

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
