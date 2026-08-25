---
name: annotate-function
description: Use when a curator names one or more genes/gene products and wants a literature-driven review of their GO function annotations — evaluate existing annotations, exhaustively search the evidence, and PROPOSE (never create) an annotation set across MF/BP/CC with supporting references and evidence.
---

# annotate-function

Given one or more genes/gene products, evaluate their existing GO annotations
against the literature, do an exhaustive evidence search, and **propose** a
well-supported annotation set (MF / BP / CC) with the references and evidence to
back each one.

**This skill only proposes annotations. It does not create or edit any
annotation, and does not build GO-CAM models.** The deliverable is a report the
curator uses to decide what to enter. If the user wants to act on the proposal,
that is a separate step with the `noctua` skill.

## Before starting — pin down the inputs (ask only if ambiguous)

- **Gene/product identity and species.** Resolve to the ID space Noctua uses
  (UniProt / MGI / etc.). Use the `uniprot-database` skill to resolve the
  identifier and grab the canonical name and sequence; use the `amigo` skill to
  find the entity in Noctua's ID space.
- **Scope.** All three aspects, or limit to MF / BP / CC? Default: all three.
- **Depth.** Quick pass vs. exhaustive. Default: exhaustive (steps below).

## Phase 1 — Evaluate existing annotations

- Pull existing experimental GO annotations for the gene(s) with `amigo` — MF, BP, and CC
  unless the scope was limited
- Separately check if IBA annotations exist for this gene
- For each annotation, record the **GO term, evidence code, and reference**.
- Look up every cited paper, retrieve the **full text** (`pubmed-eutils` to
  find/resolve; fetch full text where available), and confirm the annotation is
  actually supported — correct term, correct aspect, appropriate evidence code.
- Flag annotations that are **unsupported, over- or under-specified, or
  mis-aspected**, and suggest a concrete edit (corrected term + evidence).
- **Also pull existing annotations for close orthologs.** Identify close
  orthologs (`uniprot-database` ID mapping) and retrieve their MF/BP/CC
  annotations with `amigo`. Note where the ortholog set is annotated to
  functions the queried gene is not — these are candidate gaps to test against
  the literature in Phase 2 — and flag functions supported only by transfer
  (e.g. ISS/IBA) vs. direct experiment.

## Phase 2 — Exhaustive literature review

- Search PubMed (`pubmed-eutils`) for any other evidence describing the gene's
  function, beyond what is already cited.
- For each reference, state whether it **supports an existing MF/BP/CC or adds a
  new/different one**.
- Prefer the **full text**. Extract the specific experiment and result that
  grounds each proposed annotation, not just the authors' claim.
- **Explicitly list every paper for which only the abstract was available**, and
  do NOT infer findings beyond what the abstract states. Curation quality
  depends on this.
- Use `gocam-best-practice` to shape the proposed annotations correctly (aspect
  boundaries, causal relations, appropriate GO terms) and the OLS MCP to pick
  and verify exact GO IDs.

## Phase 3 — Phylogenetic / orthology context

- Check whether the gene(s) or **close orthologs** are the subject of
  phylogenetic analyses. Cite those papers and summarize the key findings
  (family, conserved function, functional divergence).
- Note relevant orthology (via `uniprot-database` ID mapping) and any existing
  phylogenetic (IBA / PAINT) annotations seen in Phase 1 — these say whether a
  function is inferred by descent vs. directly demonstrated.

## Deliverable — a written report

**Always** save the full report to a text file in the user's home directory —
this is required, not optional. Name the file after the gene(s), plus any other
information that makes it easy to find later (species, aspect if scoped, date).
For example: `annotation-review_mouse-Pex5_MF_2026-08-05.txt`, or for a small
set `annotation-review_Pex5-Pex7_2026-08-05.txt`. Tell the user the file path.

Structure:

1. **Current annotations** — a verdict per annotation (confirmed / edit /
   remove) with the reason.
2. **Proposed annotations** — MF / BP / CC, each with GO ID, supporting
   reference(s), suggested evidence code, and whether the support came from full
   text or abstract only.
3. **Phylogenetic context** — cited and summarized.
4. **Open questions / abstract-only gaps** — where the evidence is thin.

Close by reminding the user this is a proposal; entering or modelling the
annotations is a separate, curator-driven step.
