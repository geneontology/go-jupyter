# Exercise 04: Reviewing and completing a GO-CAM model

In this exercise you'll work with a real (but incomplete) GO-CAM model
on the Noctua dev server. The model describes the **serotonin and
melatonin biosynthesis pathway in Drosophila**.

The model has the right gene products, biological processes, causal
chain, and cellular locations — but all the **molecular functions are
set to the root term** `GO:0003674` (molecular_function), which means
"we don't know yet". Your job is to figure out the correct MFs and the
evidence that supports them.

## The model

The incomplete model is: **gomodel:69d97c3300000000**

This can be browsed: http://noctua-dev.berkeleybop.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A69d97c3300000000

## Part 1: Review the model

Ask the agent to fetch and summarize this model from the dev server.

Ask the agent to draw the model as an ascii diagram and summarize it.

## Part 2: Identify the missing molecular functions

- Check existing GO annotations
- Search PubMed for papers about these genes
- Search the OLS for candidate MF terms, and for CHEBI terms that act as intermediates

Start with Trhn — what enzyme activity does it have

## Part 3: Plan the complete model

Ask the agent to make an ascii diagram showing what edits it would make to the model. Write this to a file.

* EXERCISE 4 Completed! The agent should tick this off in PROGRESS.txt in the home directory now.

## Part 4: Create your own model

Ask the agent to create a new model that is a copy of this test one

(this will be created on the dev server, and will be deleted later)

The agent should report out what it did in a file, and include a URL linking to the new model; e.g.

http://noctua-dev.berkeleybop.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A<YOUR MODEL ID>

(note you will not be able to click links in the main claude display due to a JupyterHub bug)

## Recap

Ask the agent what you learned in this exercise

## Before finishing:

- ensure PROGRESS.txt is updated
