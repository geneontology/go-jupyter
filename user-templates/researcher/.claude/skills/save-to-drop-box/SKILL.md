---
name: save-to-drop-box
description: Save a finished GO-CAM model to the public geneontology/go-cam-drop-box repository as a pull request carrying the model in both formats (gocam-py YAML + minerva TTL) under its noctua-dev id. Use when the user asks to "save", "submit", "publish", or "keep" a model so it can be reviewed and promoted into production GO-CAM. The model must exist on noctua-dev, be stored there, and be production-worthy.
---

# Save a model to the GO-CAM drop box

This skill submits one finished GO-CAM model to
**https://github.com/geneontology/go-cam-drop-box** as a pull request. CI
validates every submission; a maintainer merges; merged models are copied into
production `noctua-models` at the next Noctua maintenance outage. This is how a
curator "saves" work from this environment so it survives and reaches production.

The drop box's own `CLAUDE.md` is the authoritative contract (fetch
`https://raw.githubusercontent.com/geneontology/go-cam-drop-box/main/CLAUDE.md`
if unsure). The essentials are below.

## The contract (since 2026-09-24): one model, two files, one id

- **The model lives on noctua-dev.** Its id is the one minerva minted there,
  e.g. `gomodel:6ab067da00000569`. That id is permanent: it is the id in both
  files, the filename of both files, and the production id after promotion.
  **Do not mint or rewrite ids** (the old `gcdb-<UUID>` scheme is retired).
- **The model is stored on dev** (step 2 below) and its state is `production`.
- **Two files, exported from that same stored state:**
  `models/<id>.yaml` (gocam-py YAML) and `models/<id>.ttl` (minerva's own
  Turtle). The YAML is the review surface; the TTL is what enters production.
  CI checks that they agree exactly, so **never hand-edit either file** —
  change the model on dev and re-export both.
- **Production-worthy.** CI enforces: `production` state, a connected causal
  graph (≥1 causal edge, no orphan activity), evidence on assertions, real and
  current ontology terms, and the noctua-models QC battery over the TTL (no
  disconnected individuals such as orphaned evidence, no multiply reified edges).

A model that exists only as notes or a YAML draft here cannot be submitted:
build it on noctua-dev first (the `noctua` skill), then come back.

## Step 0 — confirm the model is on dev

```sh
set -a; [ -f ~/.env ] && . ~/.env; set +a      # BARISTA_TOKEN
barista get-model --model <id>                  # must succeed; note the title
```

## Step 1 — finish it on dev: comments and state

Anything that should travel with the model goes on the model, as annotations:

```sh
barista update-metadata --model <id> --add --comment "Curated with GO AI HUB. <one line on what the model represents>"
barista update-metadata --model <id> --state production
```

Fix anything else on dev too (the `noctua` skill). If you removed evidence from
an edge, delete the evidence individual as well; orphaned evidence fails CI.

## Step 2 — store the model on dev

An unstored model exists only in minerva's memory and is lost at the next dev
restart. Store it, then verify the store took:

```sh
curl -s -X POST "http://barista-dev.berkeleybop.org/api/minerva_public_dev/m3BatchPrivileged" \
  --data-urlencode "token=$BARISTA_TOKEN" --data-urlencode "intention=action" \
  --data-urlencode "provided-by=http://geneontology.org" \
  --data-urlencode 'requests=[{"entity":"model","operation":"store","arguments":{"model-id":"gomodel:<id>"}}]' \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["message-type"], d.get("message"))'
# expect: success ...
barista get-model --model <id> | grep -o '"modified-p": *[a-z]*'      # expect: "modified-p": false
```

## Step 3 — export both files from that state

```sh
mkdir -p ~/drop-box-out && cd ~/drop-box-out
barista export-model --model <id> -f gocam-yaml -o <id>.yaml
curl -s -X POST "http://barista-dev.berkeleybop.org/api/minerva_public_dev/m3Batch" \
  --data-urlencode 'requests=[{"entity":"model","operation":"export","arguments":{"model-id":"gomodel:<id>"}}]' \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"]["export-model"])' > <id>.ttl
head -c 300 <id>.ttl            # Turtle, ontology IRI http://model.geneontology.org/<id>
grep -m1 '^id:' <id>.yaml       # id: gomodel:<id>
grep -m1 '^status:' <id>.yaml   # status: production
```

Do both exports back to back, after the store, with no edits in between. If you
edit the model afterwards, repeat steps 2 and 3.

## Step 4 — authenticate gh (once per user)

The PR is opened as the curator, so `gh` must be logged in as them.

```sh
gh auth status
```

If not logged in, start the **device flow** and relay it to the user (they are
already in a browser — JupyterLab — so this is just a new tab):

```sh
gh auth login --hostname github.com --git-protocol https --web
```

Tell the curator: *"Open https://github.com/login/device in a new browser tab,
enter this code: `…`, and authorize."* Wait, then re-check `gh auth status`.
The login persists in `~/.config/gh`. Only GitHub GO-organization members can
submit.

## Step 5 — fork, add both files, open the PR

```sh
gh repo fork geneontology/go-cam-drop-box --clone --remote --default-branch-only
cd go-cam-drop-box
git checkout -b add-<id>
cp ~/drop-box-out/<id>.yaml ~/drop-box-out/<id>.ttl models/
git add models/<id>.yaml models/<id>.ttl
git commit -m "Add <id> (<short title>)"
git push -u origin add-<id>
gh pr create --repo geneontology/go-cam-drop-box \
  --title "Add model <id> (<short title>)" \
  --body "What the model represents, in a few lines. Built and stored on noctua-dev as gomodel:<id>; YAML and TTL exported from the same stored state."
```

## Step 6 — watch CI and fix if needed

The `validate` check must pass before merge:

```sh
gh pr checks --repo geneontology/go-cam-drop-box <pr-number>
gh run view --repo geneontology/go-cam-drop-box <run-id> --log-failed     # on failure
```

Failures map to the seven gates. **Every fix is made on dev, then both files
are re-exported (steps 2–3) and pushed to the same branch.** Common ones:

| CI says | Do on dev |
|---|---|
| id/filename mismatch | you renamed something; the id is the dev id, both filenames are `<id>.*` |
| `status 'development' not in allowed_statuses` / TTL state != YAML status | `barista update-metadata --model <id> --state production`, store, re-export both |
| model comments differ | comments were added to the YAML by hand; put them on the model with `update-metadata --add --comment`, re-export both |
| YAML ↔ TTL agreement failures | the files came from different states; store, then re-export both back to back |
| `check-disconnected-individuals.rq` rows | orphaned evidence (or other) individuals; delete them on dev, store, re-export |
| `check-multiply-reified-edges.rq` rows | the same edge has evidence attached twice as separate axioms; remove the duplicate on dev |
| LinkML / ontology-term failures | a term is wrong or obsolete; fix on dev |

## What "submitted", "merged" and "promoted" mean

Tell the curator this when you hand over the PR:

- **Submitted (PR open)** — the model is production-ready and queued for GO
  Central review. The work is **safe**; this is the durable save. An open PR is
  a normal resting state.
- **Merged** — accepted; it will be copied into production `noctua-models`,
  under the same id, at the next Noctua maintenance outage (second and fourth
  Thursdays). `PROMOTIONS.md` in the drop box records each batch.
- **Promoted** — live in production Noctua under `gomodel:<id>`.

Once merged, the drop box is the source of truth for that id until promotion,
and production is after. Edits made on noctua-dev afterwards are **not**
carried anywhere by themselves: if the curator changes a submitted or merged
model, say so and offer to carry the change back (update the open PR, or open a
new PR), or the edit is silently overwritten by the next dev refresh.

## Don't

- Don't submit a model that is not on noctua-dev, or not stored there.
- Don't hand-edit the YAML or the TTL, and don't write a YAML from scratch.
- Don't mint, reuse or rewrite `gomodel:` ids; don't fabricate ontology terms.
- Don't treat noctua-dev itself as a save — unstored models vanish, and even
  stored dev models are a proving ground, not production.
- Don't chase a merge or tell the curator something is wrong because their PR
  is still open; review is manual.
