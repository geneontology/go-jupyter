# 🧬 GO Biocuration Playground

This is a sandbox for doing **Gene Ontology biocuration with an AI agent**.
Claude Code is pre-wired with the tools a GO curator actually uses — ontology
lookup, the literature, protein databases, the standard annotation set, and
the GO-CAM model store (Noctua) — so you can explore real curation workflows
without setting anything up.

There is no fixed curriculum here. It's a playground: bring a gene, a paper,
a pathway, or a half-formed question, and work it through with the agent.

## Getting started

Find the window marked **Claude Code** (if you don't see one, choose
**File → New → Terminal** and press ENTER). Then just talk to it in plain
language. A good opener is:

```
> What can you help me with here?
```

Claude will introduce itself and the tools it has on hand.

## Things you can try

- **Ask about a gene or protein** — "What do we know about Epe1 in fission
  yeast?" Claude can pull existing GO annotations, UniProt records, and
  relevant papers.
- **Explore an ontology** — "Find me GO terms for serotonin biosynthesis,"
  or "what's the CHEBI term for melatonin?"
- **Review a GO-CAM model** — give it a model ID and ask for a summary or an
  ASCII diagram of the causal chain.
- **Draft a model** — describe a pathway and have Claude sketch the
  activities, inputs, locations, and causal relations, following GO-CAM
  best practice.
- **Dig into the literature** — "Find recent papers on the molecular
  function of Trhn and summarize the evidence."

## A few ground rules

- **Noctua work happens on the test/dev server by default.** Claude won't
  touch production models. If you want to experiment with edits, ask it to
  create a *new* model on the dev server — don't edit models you didn't
  make.
- **Be transparent and check the work.** Claude will tell you which tool it's
  using. It can be wrong, and it won't claim to have read a full paper from
  just an abstract — verify before you trust an annotation.
- **Your files persist for this session.** Treat your home directory as
  scratch space; save notes, drafts, and diagrams wherever you like.

## Saving a model beyond this session

Files here live with your session — but a **finished, production-worthy GO-CAM
model** can be saved for real. Ask Claude to *"save this model to the drop
box"*: it packages the model, helps you sign in to GitHub once, and opens a
pull request to the public `go-cam-drop-box` repository, where it's validated
and reviewed. (Only complete models are accepted, and only GitHub GO-org
members can submit.)

## Data & privacy

This is a shared, monitored environment. Your activity and usage — including
system and session logs and usage traces — may be reviewed to analyze and
improve the service. Please don't store personal secrets or anything you
wouldn't want examined here.
