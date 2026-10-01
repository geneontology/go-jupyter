# Writing and sharing skills on the GO AI Hub

This page covers what is particular to the hub: where your skills come from,
how to change one, how to add one, and how to get it to your colleagues. For
what a skill is and how to write a good one, read the AI4Curators guides first;
this page does not repeat them:

- [What is a skill](https://ai4curation.io/aidocs/reference/claude-skills/)
- [How to write curation skills](https://ai4curation.io/aidocs/how-tos/author-skills/)
- [Break work into skills](https://ai4curation.io/aidocs/patterns/skills-before-automation/)
  (why skills come before automation)
- [The GO AI Hub](https://ai4curation.io/aidocs/case-studies/go-ai-hub/)
  (what the hub is, and what the first workshop found)

## Where your skills come from

Skills are not written in this repository. They live in their own
repositories, listed in [`skill-sources.txt`](../skill-sources.txt):

| Repository | Clone in your home | What it holds |
| --- | --- | --- |
| [geneontology/go-skills](https://github.com/geneontology/go-skills) | `~/go-skills` | GO-CAM (`noctua`, `save-to-drop-box`, `gocam-best-practice`), `gene-review`, `annotate-function`, PubMed, UniProt, AmiGO |
| [geneontology/go-ontology](https://github.com/geneontology/go-ontology) | `~/go-ontology` | Ontology editing skills (taxon constraints, obsoletion, mappings, ...) |

Each skill Claude can use is a link in `~/.claude/skills/` pointing into one of
those clones. To see them:

```bash
ls -l ~/.claude/skills
```

An arrow (`noctua -> ../../go-skills/skills/noctua`) is a shared skill. A plain
directory is one you made yourself, or one the tutorial template put there
(`exercise`, `recap`).

**Keeping current is automatic.** Every five minutes the hub checks whether
go-skills or go-ontology moved. If your clone is on `main` (or `master`) with no
local changes, it is fast-forwarded and new skills are linked. A running Claude
session picks up the new text the next time it uses the skill. You do nothing.

**Your edits pause that.** If your clone is on another branch, or has
uncommitted changes, the hub leaves it alone, because that is you working on a
skill. Get back on the automatic track with:

```bash
cd ~/go-skills && git switch main && git pull
```

## Change an existing skill

Because the skill is a link into your clone, an edit in the clone is what
Claude runs next time. You can try a change in your own session before anyone
else sees it.

```bash
cd ~/go-skills
git switch -c noctua-store-step      # a branch: pauses automatic updates
# edit skills/noctua/SKILL.md, or ask Claude to
# ... use the skill in a session and see whether it behaves better ...
git add -A
git commit -m "noctua: say which token the store step needs"
git push -u origin noctua-store-step
gh pr create --fill
```

You do not need `gh auth login`: signing in to the hub signed in `gh` too.
You do not have to type any of this either. Asking Claude "commit this change to
the noctua skill on a branch and open a pull request to go-skills" works.

go-skills' [CONTRIBUTING.md](https://github.com/geneontology/go-skills/blob/main/CONTRIBUTING.md)
has the full checklist, including how to make small wording fixes in the
browser without a session.

## Add a new skill

The fastest route is to do the task once with Claude, then turn the session
into a skill. At the end of a session that went well, ask:

> Turn what we just did into a new skill in `~/go-skills/skills/<name>/` on a
> new branch. Follow `~/go-skills/CONTRIBUTING.md`. Put the steps that must
> always happen, and the checks you ran, in `SKILL.md`. Move reference material
> into `references/`. Do not include anything specific to the gene we worked on.

Then make the new skill visible to Claude. The hub links new skills only when
go-skills itself moves, so link your draft by hand:

```bash
ln -s ../../go-skills/skills/<name> ~/.claude/skills/<name>
```

Start a new Claude session (`/clear`, or exit and relaunch) and try the skill on
a *different* example from the one you built it on. That is the test that
matters: a skill that only works on the case it came from is a transcript, not
a procedure. When it works, push and open a pull request as above.

If you switch back to `main` before your pull request is merged, the hub removes
the link (its target no longer exists on `main`). It comes back as a normal
shared skill once the pull request merges.

### Where should the skill go?

| The skill is for | Put it in |
| --- | --- |
| GO curation any GO curator does: annotation, GO-CAM, literature, lookups | go-skills |
| Editing the GO ontology itself | go-ontology, under `.claude/skills/` |
| Your group or model organism database only | Your group's repository, or a personal skill (below) |
| Only you, or an experiment | A personal skill (below) |

Skills in go-skills reach every curator on the hub within minutes of a merge.
Hold a skill to that standard: it should work from a fresh home with no
credentials, and do what its `description` says.

### A personal skill

A plain directory in `~/.claude/skills/` is yours. The hub never touches it.

```bash
mkdir -p ~/.claude/skills/my-mod-conventions
# write ~/.claude/skills/my-mod-conventions/SKILL.md, or ask Claude to
```

It is not backed up and nobody else gets it. Once it proves useful, move it to
go-skills or your group's repository.

## A checklist before you open the pull request

Most of this comes from the
[AI4Curators skills guide](https://ai4curation.io/aidocs/how-tos/author-skills/)
and go-skills' CONTRIBUTING.md.

- [ ] The `description` says *when* to use the skill, in the words a curator
      would use. Claude decides whether to load a skill from its description
      alone.
- [ ] `name` matches the directory name, lowercase with hyphens.
- [ ] `SKILL.md` is under 500 lines. Detail is in `references/`.
- [ ] Identifiers (GO terms, PMIDs, UniProt accessions) are looked up with a
      tool, never written from memory. See
      [Make identifiers hard to fake](https://ai4curation.io/aidocs/patterns/ground-identifiers/).
- [ ] If a lookup fails, the skill says to stop and report it, not to carry on
      with a guess. The first workshop's worst failure was an agent quietly
      filling in abstracts after a PubMed tool failed.
- [ ] You tried it on a second example in a fresh session.
- [ ] The skill writes only to the Noctua development server, or says clearly
      where it writes.

## Using the same skills outside the hub

The skills use the open [Agent Skills](https://agentskills.io/specification)
format, so they work in Claude Code on your own machine, Claude Code on the web,
and other agents that read `SKILL.md` (Codex, Cursor, Gemini CLI).

**To use them.** Install one skill, for your user, from any directory:

```bash
npx skills add geneontology/go-skills --skill gene-review -g -a claude-code
npx skills update          # later, to pick up changes
```

Installed this way, a skill does not update itself the way it does on the hub.
Run `npx skills update` now and then.

**To work on them.** Do what the hub does: clone go-skills and link the skills
you want into `~/.claude/skills/` (or a project's `.claude/skills/`). Then a
`git pull` updates them and your edits can become pull requests.

```bash
git clone https://github.com/geneontology/go-skills.git ~/go-skills
ln -s ~/go-skills/skills/noctua ~/.claude/skills/noctua
```

Claude Code also reads skills from a repository's own `.claude/skills/` when you
start it inside that repository. That is how go-ontology's skills reach anyone
who opens a session in a go-ontology checkout, on the hub or off it.

## Sharing what you learned

A skill change is the most durable way to share a lesson: the next curator gets
it without reading anything. When you find a fix but are not ready to edit the
skill, open an issue on go-skills describing what went wrong and what worked
instead. Someone who maintains the skill can turn it into a change.
