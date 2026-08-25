# Exercise 02

This exercise takes us through the use of additional tools that can be configured in an environment

## Pubmed searches

Try asking the agent to query for papers about the function of Epe1 in S. pombe. Ask for most recent 10

What do you get back?

* UNLOCK: the agent should use NCBI E-utilities (via curl) to search PubMed

## Working with the output of tools

Ask the agent for a CSV containing the results of your pubmed query

Explore the CSV in your left hand tab

Try asking the agent to reformat this - e.g. add a column with the full abstract

## OLS MCP

Pick one of the papers, and ask the agent to annotate the GO terms that can be found in the abstract

Suggestion: Yaseen et al (last: Allshire)

* UNLOCK: you (should) have used the OLS MCP tool

Ask the agent to create a CSV with the PMID and the terms, alongside the snippet/context

## GO annotation queries

Ask the agent to find all existing annotations for this gene. Make sure to ask it for the PMIDs.

Do any of the results stand out as interesting? Ask the agent to dig into the NOT annotation.

## Fetching PDFs

Try asking the agent to get a PDF for one of the papers. What happens?

Try ask the agent to do this for the Yaseen at al

Ask the agent to pull out excerpts that support existing GO annotations.

* EXERCISE 2 Completed! The agent should tick this off in PROGRESS.txt in the home directory now.


## Open Ended Exploration

Keep exploring...

## Recap

Ask the agent what you learned in this exercise

## Before moving on to next section:

- ensure PROGRESS.txt is updated
