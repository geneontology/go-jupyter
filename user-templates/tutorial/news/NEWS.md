# What's new

Short operator announcements. You see this at the start of a session only when
it has changed since you last read it — if nothing is new, it stays out of your
way.

---

## 2026-10-14 — Skills are now read-only links to go-skills; your own skills stay yours

The skills Claude uses (`~/.claude/skills/*`) now link into one checkout of
geneontology/go-skills (and of go-ontology, for the ontology skills) that the
hub keeps current and nobody can edit. A merge there reaches every home within
minutes, every time. Until now each home had its own editable clone, and a stray
file could silently stop it updating: six homes were running weeks-old skills.

- To change a skill, ask Claude to open an issue against go-skills, or a pull
  request from a fork. The linked files cannot be edited, and a copy edited in
  your home reaches nobody else.
- `~/go-skills` has left your home: moved to `~/.go-jupyter/retired/` if it was
  untouched, left in place if you had work on a branch (ask Claude to turn that
  into a pull request).
- A skill you wrote yourself in `~/.claude/skills/` is untouched and still works.
  Ask Claude to propose it to go-skills when you want every curator to have it.
- If a copy of yours had the same name as a go-skills skill, the hub set it aside
  under `~/.go-jupyter/skill-overrides/` and the canonical one took over; the
  login banner says so.
- `~/go-ontology` is unchanged: it is still your clone for ontology work.

---

## 2026-10-12 — Who can sign in is now a GO permission

Access to this hub is now recorded in GO's `users.yaml` (geneontology/go-site)
as the `go-ai-hub` permission, the same file that holds Noctua permissions.
If you are reading this, you have it. The same permission will decide who can
submit models to the go-cam-drop-box. To add a colleague, ask a GO admin to add
the permission to their `users.yaml` entry; it takes effect within the hour.

---

## 2026-09-29 — Ontology editing skills, with one limit

A checkout of geneontology/go-ontology sits in your home at `~/go-ontology`
(its agent skills and the editable ontology files), and its skills for chemical
entities, design patterns, external term lookup, mappings, pull-request review,
reactions, research, taxon constraints and term obsoletion are on. Start from
inside `~/go-ontology`; branches and pull requests go to go-ontology.

The limit: the ontology build tools (`robot`, the `make` targets, the reasoner)
cannot run on this machine yet. A step that needs them stops with a message
saying so; go-ontology's CI runs the full QC and reasoning on your pull request
instead. Lookups (`runoak`, `obo-grep.pl`), editing and review guidance work.

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
