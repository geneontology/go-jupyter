---
name: save-to-drop-box
description: Save a GO-CAM model the user has been working on to the public geneontology/go-cam-drop-box repository as a pull request. Use when the user asks to "save", "submit", "publish", or "keep" a model so it can be reviewed and (later) promoted into GO-CAM. The model must be complete and production-worthy.
---

# Save a model to the GO-CAM drop box

This skill submits one finished GO-CAM model to
**https://github.com/geneontology/go-cam-drop-box** as a pull request. That
repo's CI validates every submission; a maintainer merges. This is how a
curator "saves" work from this environment so it survives and can flow toward
production.

Read the drop box's own contract for the authoritative rules (fetch
`https://raw.githubusercontent.com/geneontology/go-cam-drop-box/main/CLAUDE.md`
if unsure). The essentials are below.

## The contract

- **Format:** the model is a **gocam-py GO-CAM YAML** file.
- **Id:** top-level `id: gomodel:gcdb-<UUID>`. Mint a fresh one:
  ```sh
  python3 -c "import uuid; print(f'gcdb-{uuid.uuid4()}')"
  ```
  Never reuse an existing id. Activity ids under the model take the form
  `gomodel:gcdb-<UUID>/<local-id>`.
- **Filename:** `models/gcdb-<UUID>.yaml` — the filename must match the id.
- **Must be complete and production-worthy.** CI enforces (strictly, for now):
  `status: production`, a connected causal graph (≥1 causal relationship, no
  disconnected activity), evidence on assertions, and every ontology term
  (GO/RO/ECO/CHEBI/…) real and non-obsolete. Half-finished experiments will be
  rejected — don't submit them.

## Step 1 — produce the model as gocam YAML

Two ways, whichever fits what the curator has:

- **Author it directly.** If the model exists as reasoning/notes/a draft here,
  write it out as gocam-py YAML following the schema and the drop box's
  `examples/`. This is usually the simplest path.
- **Export a Noctua dev-server model.** If they built it on the dev server,
  fetch its minerva JSON (via the `noctua` skill / barista) and convert with
  gocam-py:
  ```python
  from gocam.translation import MinervaWrapper
  model = MinervaWrapper.minerva_object_to_model(minerva_json)
  ```
  then serialize `model.model_dump(exclude_none=True)` to YAML.

Set the top-level `id` to `gomodel:gcdb-<UUID>`, `status: production`, and save
it as `gcdb-<UUID>.yaml`.

## Step 2 — sanity-check before submitting

Do a quick local check so the PR isn't obviously red (CI runs the full,
authoritative validation). Confirm: `id` matches the filename; `status:
production`; at least one activity with a `causal_associations` edge and no
orphan activity; evidence present; and you did not invent any ontology term.

## Step 3 — authenticate gh (once per user)

The PR is opened as the curator, so `gh` must be logged in as them.

```sh
gh auth status
```

If not logged in, start the **device flow** and relay it to the user (they are
already in a browser — JupyterLab — so this is just a new tab):

```sh
gh auth login --hostname github.com --git-protocol https --web
```

This prints a one-time code (e.g. `AB12-CD34`) and the URL
`https://github.com/login/device`. Tell the curator: *"Open
https://github.com/login/device in a new browser tab, enter this code: `…`, and
authorize."* Wait for them to finish, then re-check `gh auth status`. It only
has to be done once — the login persists in `~/.config/gh`.

Only GitHub organization members can submit; if the curator isn't a GO-org
member, their PR won't be accepted.

## Step 4 — fork, add, and open the PR

```sh
gh repo fork geneontology/go-cam-drop-box --clone --remote --default-branch-only
cd go-cam-drop-box
git checkout -b add-gcdb-<UUID>
cp <path-to-your-model>.yaml models/gcdb-<UUID>.yaml
git add models/gcdb-<UUID>.yaml
git commit -m "Add gcdb-<UUID>"
git push -u origin add-gcdb-<UUID>
gh pr create --repo geneontology/go-cam-drop-box \
  --title "Add model gcdb-<UUID>" \
  --body "Brief description of what this model represents."
```

## Step 5 — watch CI and fix if needed

The `validate` check must pass before merge. Check it and, if red, read the
failure and fix the model, then push again to the same branch:

```sh
gh pr checks --repo geneontology/go-cam-drop-box <pr-number>
# on failure:
gh run view --repo geneontology/go-cam-drop-box <run-id> --log-failed
```

Common failures map to the four gates: bad `gcdb-` id / filename mismatch;
LinkML schema violation; not production-worthy (status, connectivity,
evidence); or an ontology term that doesn't exist or is obsolete. Fix and
re-push until the check is green, then hand the curator the PR URL and let them
know a maintainer will review and merge.

## What "submitted" and "merged" mean

Tell the curator this when you hand over the PR — it's the difference between
"my work is safe" and "my work is in limbo," and they should not have to guess:

- **Submitted (PR open)** — the model is production-ready and queued for **GO
  Central review**. The work is **safe**; this is the durable save. Merging is a
  manual editorial step by a GO Central maintainer, so an open PR is a normal
  resting state, not a problem to chase.
- **Merged** — accepted by GO Central; it will be available in a future release.

Once merged, that drop-box entry is the **source of truth for that model ID**. It
flows onward to production, and when it does it **clobbers** other copies —
including anything edited on noctua-dev afterwards. So if the curator later
changes a model that has already been submitted or merged, point that out and
offer to carry the change back: update the open PR, or open a new PR if it was
already merged. Otherwise their edit is silently overwritten downstream.

## Don't

- Don't submit incomplete or experimental models — the gate is strict.
- Don't reuse a `gomodel:` id or fabricate ontology terms.
- Don't treat noctua-dev as a save, or imply a model is safe because it's on the
  dev server — models there can be permanently lost. This drop box is the
  durable save, and a model does not need to be on noctua-dev to be submitted.
- Don't chase a merge or tell the curator something is wrong because their PR is
  still open — review is manual and takes as long as it takes.
