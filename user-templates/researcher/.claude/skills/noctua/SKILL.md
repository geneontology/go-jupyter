---
name: noctua
description: Use whenever you need to access the GO-CAM store (Noctua). This is accomplished via an API called barista.
---

# About

Use for listing and searching models, create/read/update on models.

## Command Line Client

This uses the `noctua` command line tool, which should have been installed when we ran `uv tool install noctua`

I recommend:

```
alias barista='noctua barista'
```

You can get help at any time

```
barista --help
```

subcommands also have help

## Tokens — do this FIRST, before any model work

A barista token is **personal**: it comes from a human logging in with their
ORCID, it carries that person's identity (models they create are attributed to
it), and it **expires**. There is no shared or service token — each curator uses
their own.

**Set this up at the start of a session, not after something fails.** Building a
model and only then discovering you can't write wastes the user's time.

### Step 1 — load any token the user already saved

```sh
set -a; [ -f ~/.env ] && . ~/.env; set +a
```

Run this **before every barista command** (a saved token lives in `~/.env` and is
not loaded automatically). If a previous session already set one up, this is all
you need.

### Step 2 — verify it actually works

**Do not assume a token is good just because `BARISTA_TOKEN` is set, and do not
use `list-models` as the check** — `list-models` reads the search index and
succeeds with no token at all, or with a garbage one. It proves nothing.

Verify with an authenticated call:

```sh
noctua barista get-model --model <any-known-model-id>
```

- Works → you're set.
- `"You are using a bad token; please remove it."` → the token is invalid or
  expired. Go to step 3.
- `BARISTA token not provided` → no token yet. Go to step 3.

### Step 3 — walk the user through getting one

Only the user can do this; it's an interactive login.

1. Open **http://noctua-dev.berkeleybop.org/workbench/noctua-landing-page/**
2. Click **Login** and authenticate with ORCID.
3. Copy the barista token shown on the page.

Logging in on the web page does **not** hand the token to this shell — they have
to paste it. Offer to save it so they only do this once:

```sh
echo 'BARISTA_TOKEN=<paste-token-here>' > ~/.env && chmod 600 ~/.env
```

Then re-run step 1 and re-verify with step 2.

### The token is the curator's identity — it becomes provenance

The token is not just access, it is **who the work belongs to**. Barista stamps
the ORCID behind it onto every model as `contributor`, and that provenance
travels: it is carried in the GO-CAM YAML, per activity, all the way into a
go-cam-drop-box submission. Nothing downstream validates it, so a wrong ORCID is
never caught — it just quietly ships as a false claim about who did the science.

Two practical consequences:

- **Each curator uses their own token.** Never reuse someone else's, and never
  carry one user's token into another user's work.
- **Sanity-check the identity.** Barista responses include the ORCID as `uid`
  (e.g. `"uid": "https://orcid.org/0000-0002-1825-0097"`). If it isn't the
  person you're working with, stop and say so before building anything.

The token is stored in the user's own `~/.env` (mode `0600`); ordinary unix
permissions on the box are the protection, which is proportionate for a dev
server.

## Read Access

To dump a model in minerva JSON:

```
barista export-model --model 646ff70100002557
```

This is the low-level triple representation used natively in Noctua

In gocam-yaml:

```
barista export-model --model 646ff70100002557 -f gocam-yaml
```

This is the structured version

## Search and Browsing models

Most recent 50:

```
barista list-models --limit 50
```

All that reference a gene product

```
barista list-models --gp UniProtKB:Q14457
```

Search by title

```
barista list-models --title "immune"
```

## IMPORTANT — noctua-dev is a proving ground, not a save

**Do not tell the user their work is safe because it is on noctua-dev.** The dev
server is a place to build and test models. Models there **can and do disappear**:
a model can read back successfully and still be gone from the store later
(`UnknownIdentifierException: Could not find a model for id: …`), forcing a
rebuild.

**Why this happens — the mechanism matters.** A model built through these barista
commands lives in **minerva's memory**. It reads back perfectly, it is editable,
and it looks completely real — but it is not on disk until something triggers a
**real save**. If the dev server restarts before that, anything unsaved is simply
gone: a model that has picked up a real save survives a reboot, one that has not
blinks out.

So "I just read it back and it's fine" proves the model exists **right now**, not
that it will survive. Never treat a successful read as evidence of durability.

Two rules follow:

- **Never explain a missing model as "search-index lag."** That explanation is
  wrong and leaves the curator waiting for models that no longer exist. If a
  model is missing, check whether it still exists
  (below) and say plainly what you find.
- **`list-models` and the landing page are not proof of persistence.** They read
  the search index. The authoritative check is reading the model by ID:

  ```sh
  noctua barista get-model --model <model-id>
  ```

  `UnknownIdentifierException` means the model is **gone** — not hidden, not
  pending. It must be rebuilt.

**The durable save is the go-cam-drop-box** — see the `/save-to-drop-box` skill.
Since 2026-09-24 a submission is the model in **two formats under its dev id**
(gocam-py YAML + minerva TTL), both exported from the **same stored state** of
the model on noctua-dev. So a model **must** exist on noctua-dev, be **stored**
there, and be in `production` state before it can be submitted; nothing can be
submitted from notes or a hand-written YAML.

### Store, state, comments, export

- **Store** after meaningful work and always before exporting. An unstored model
  lives only in minerva's memory and is gone at the next dev restart (this has
  cost curators finished models). Store with the minerva `store` operation and
  verify `"modified-p": false` afterwards — the exact commands are in
  `/save-to-drop-box`, step 2.
- **State and comments are model annotations**, set on dev:
  `barista update-metadata --model <id> --state production` and
  `barista update-metadata --model <id> --add --comment "..."`. Never add
  comments to an exported YAML by hand; CI compares YAML and TTL comments.
- **Export both files back to back** from the stored state (`/save-to-drop-box`,
  step 3). Any later edit means store + re-export both again.

### Evidence hygiene

When you remove evidence from an edge (`remove-annotation` of an `evidence`
value, or deleting/re-adding an edge), also **delete the evidence individual**
(`barista delete-individual`). Evidence individuals that no axiom references are
"disconnected individuals"; production's QC battery flags them and the drop-box
CI now rejects them. Likewise avoid attaching evidence to the same edge twice as
separate axioms.

### Offer the durable save — don't force it

When a curator has built something they care about, **tell them where it stands
and offer to submit it**. Then respect the answer. Plenty of work here is
deliberate experimentation that nobody wants to keep, and that is fine — the
point is that the user is *informed*, not that everything gets submitted.

Say something like: *"This currently only exists on the dev server, which can
lose models. The durable save is a PR to the go-cam-drop-box — want me to submit
it?"*

### Editing a model that was already submitted or merged

Once a model is **merged** into go-cam-drop-box, that becomes the **source of
truth for that ID**. It flows onward to production, and when it does it will
**clobber** other copies — including any edits made on noctua-dev afterwards.

So if the user edits a model on noctua-dev that has already been submitted or
merged, **point this out and offer to carry the change back**:

- **PR still open** → update that PR with the new version.
- **Already merged** → open a new PR against the merged model.

Otherwise their edit looks fine on noctua-dev and is silently overwritten later.

**Not currently supported:** pulling a merged drop-box model that is no longer on
noctua-dev back onto the dev server to edit it. `barista create-model` cannot be
given an ID (it only takes `--title`), so a replayed model gets a fresh minerva
ID, loses its `gcdb-<UUID>` linkage, and a PR from it would fork the source of
truth instead of updating it. If a curator needs this, the simpler path is to
deprecate the old model (`model-state=deleted`) and create a new one with a note
explaining the lineage. Flag the limitation rather than improvising a round-trip.

## More Information

Please see the /gocam-best-practice skill


## Using the Barista Command-Line Tool

The `barista` command (alias for `noctua barista`) provides tools for model creation and editing.

### Key Commands

#### Viewing Models

```bash
# Export model in Minerva JSON format
barista export-model --model <model-id>

# Export in GO-CAM YAML format
barista export-model --model <model-id> -f gocam-yaml

# List recent models
barista list-models --limit 50

# Search models by gene product
barista list-models --gp UniProtKB:Q14457

# Search models by title
barista list-models --title "immune"
```

#### Creating and Editing Models

```bash
# Create a new empty model
barista create-model

# Add an individual (molecular activity, BP, or CC)
barista add-individual --model <model-id> --class <GO-term> --assign <variable-name>

# Create a relationship between individuals
barista add-fact --model <model-id> \
  --subject <variable-or-id> \
  --object <variable-or-id> \
  --predicate <relation-id>

# Add evidence to support a relationship
barista add-fact-evidence --model <model-id> \
  --subject <variable-or-id> \
  --object <variable-or-id> \
  --evidence <evidence-code> \
  --reference <PMID>
```

### Important Notes

- Commands use the **test server by default**; production requires the explicit `--live` flag
- Use variable names (via `--assign`) for readability when building complex models
- Production models with state="production" are protected against accidental deletion
- Always add evidence to support facts in models

