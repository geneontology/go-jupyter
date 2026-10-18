# What's new

Short operator announcements. You see this at the start of a session only when
it has changed since you last read it — if nothing is new, it stays out of your
way.

---

## 2026-10-18 — Two new commands: /report and /summary

- **`/report`** is your channel to the people who run this hub and maintain
  the skills. Say what happened, what annoyed you, what you wish existed, or
  what went well, in your own words; Claude records it, tied to the moment in
  the session it refers to, and offers to open an issue only when there is
  something concrete to fix. The operators read these next to the session
  traces.
- **`/summary`** shows what the session actually did, read from the session
  transcript rather than from Claude's memory: GO-CAM model writes (which
  model, which operation, which server), drop-box pull requests, commits,
  files written, and then what was looked up. The same summary is saved
  under `~/.go-jupyter/summaries/` when a session ends. Ask for it before you
  leave, or whenever you want to check what was done in your name.

---

## 2026-10-15 — Each session now has its own private /tmp

On 2026-10-14 a request file one curator's session had left in `/tmp` was picked
up by another curator's session and sent to noctua-dev with that session's
token: the first curator's model gained the second curator's name as a
contributor, and nothing else changed. `/tmp` was one directory shared by every
account on this machine.

- Your server now has its own `/tmp`, which no other account can see. It is
  emptied when your server stops, so keep anything you want under your home.
- Claude is told to create temporary files with `mktemp` or in your home, to
  stop at the first failed step, and to show you the model id in any request
  that changes a model before sending it.
- If you think a model of yours was touched by someone else's session, ask
  Claude to compare it with your drop-box submission, and tell the operators.

---

## 2026-10-14 — Shared skills now update automatically; your own skills stay yours

The skills Claude uses now come straight from GO's shared skills collection, and
everyone gets the same up-to-date version. When a skill is improved, every
curator has the new version within minutes. Before this change, each person had
their own copy, and some copies had quietly stopped updating. Six people were
working with skills that were weeks out of date.

What this means for you:

- **You can't edit the shared skills directly.** If you want a skill to work
  differently, tell Claude what you'd like changed. Claude will send the
  suggestion to the skill maintainers so the fix reaches everyone. A change made
  only in your own space would reach nobody else.
- **Your old personal copy of the skills has been put away.** If you had never
  changed it, it was moved out of sight. If you had unfinished changes in it, it
  was left where it was, and Claude can help you send those changes to the
  maintainers.
- **Skills you wrote yourself are untouched** and still work. If you'd like every
  curator to have one, ask Claude to propose it for the shared collection.
- **If one of your skills had the same name as a shared one,** the shared one now
  takes over and yours has been set aside, not deleted. The welcome message at
  login tells you if this happened.
- **Your ontology editing folder (`go-ontology`) has not changed.**

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
