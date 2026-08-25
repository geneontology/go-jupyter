# Exercise 03: Simple scripting with PANTHER

In this exercise you'll learn how to have the agent write simple scripts
for you. You don't need to know any programming for this, and you
don't even need to understand the code — the agent does the heavy lifting!

We'll use the PANTHER database, which classifies proteins into families
and assigns GO annotations.

## Part 1: Exploring the PANTHER API

Ask the agent to look up Epe1 (our friend from Exercise 02) in the
PANTHER database.

What family is it in? What GO molecular function annotations does
PANTHER assign to it?

Important: the PANTHER API returns multiple annotation sets. The ones
labelled `ANNOT_TYPE_ID_PANTHER_GO_SLIM_MF` are high-level slim terms
(e.g. "histone demethylase activity"). These are too coarse for
curation. Ask the agent to show you the **full GO annotations** instead —
these are under the annotation type `GO:0003674` (the MF root) and
contain the specific leaf-level terms you're used to working with
(e.g. "oxidoreductase activity", "protein binding").

* UNLOCK: the agent should use curl to call the PANTHER API at
  `https://pantherdb.org/services/oai/pantherdb/geneinfo`

## Part 2: Finding orthologs

Ask the agent to find the human orthologs of Epe1 using PANTHER.

What genes come back? Do any of them look familiar from the literature
you explored in Exercise 02?

* UNLOCK: the agent should use the PANTHER ortholog endpoint at
  `https://pantherdb.org/services/oai/pantherdb/ortholog/matchortho`

## Part 3: Writing a script

Now for the fun part. Ask the agent to write a Python script that:

1. Takes a gene name and organism as input
2. Looks up its full GO MF annotations (from the `GO:0003674` annotation type, NOT the slim)
3. Finds all the human orthologs
4. Looks up the full GO MF annotations for each ortholog
5. Outputs a CSV comparing the MF annotations across the family

You might say something like:

> "Can you write a Python script that takes a gene name and organism
> ID, finds its PANTHER orthologs, and makes a CSV comparing their
> full GO molecular function annotations? Use the GO:0003674 annotation
> type, not the PANTHER slim."

Once the agent writes the script, ask it to run it for Epe1 (organism 284812 for S. pombe).

Explore the output CSV in your left panel.

## Part 4: Improving the script

Look at the CSV. Are there things you'd like to improve? Some ideas:

- Add the gene symbols to make it more readable
- Include the ortholog type (LDO = Least Diverged Ortholog, O = other ortholog)
- Try it with a different gene — pick one from your own organism of interest
- Add BP (biological process, `GO:0008150`) annotations alongside MF
- What about CC (cellular component, `GO:0005575`)?

Just tell the agent what you want changed. No need to edit code yourself!

## Part 5: Critical evaluation

Compare what PANTHER says about Epe1's molecular functions against:
- What you found in the literature (Exercise 02)
- What's in the GO annotation database (Exercise 02)

Are they consistent? Are there annotations PANTHER has that GO doesn't,
or vice versa? Which set is more specific? Discuss with the agent.

* EXERCISE 3 Completed! The agent should tick this off in PROGRESS.txt in the home directory now.

## Recap

Ask the agent what you learned in this exercise

## Before moving on to next section:

- ensure PROGRESS.txt is updated
