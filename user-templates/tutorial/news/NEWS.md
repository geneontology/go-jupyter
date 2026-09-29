# What's new

Short operator announcements. You see this at the start of a session only when
it has changed since you last read it — if nothing is new, it stays out of your
way.

---

## 2026-09-29 — Ontology editing: being set up, not usable yet

A checkout of geneontology/go-ontology now sits in your home at `~/go-ontology`
(its agent skills and the editable ontology files). Its skills are **not yet
enabled** here: they rely on the ontology toolchain (`robot`, the `make`
targets, the reasoner), which this machine cannot run yet. They will be
switched on, with a note here, once that works. Until then, ontology editing
happens the usual way in go-ontology itself.

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
