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

## Tokens

Ask your the user to get a barista token. This should be on the test server:

http://noctua-dev.berkeleybop.org/workbench/noctua-landing-page/

Click "login"

The token should be in the environment

```
export BARISTA_TOKEN=<token>
```

or in `.env`

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

