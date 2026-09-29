# What's new

Short operator announcements. You see this at the start of a session only when
it has changed since you last read it — if nothing is new, it stays out of your
way.

---

## 2026-09-29 — Ontology editing skills from geneontology/go-ontology

A second skills checkout, `~/go-ontology`, holds the GO ontology's own agent
skills (chemical entities, design patterns, external term lookup, mappings,
pull-request review, reactions, research, taxon constraints, term obsoletion)
together with the editable ontology files under `src/ontology`. They appear as
skills like the others. For ontology work, start from inside `~/go-ontology`;
branches and pull requests go to go-ontology, whose CI runs the reasoner and
QC. The `runoak` and `obo-grep.pl` commands are installed for these skills.

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

## 2026-08-05 — Announcements now appear here

This is where changes to the environment get announced. Nothing else to do.
