---
name: gocam-best-practice
description: This skill should be used when creating, editing, or validating GO-CAM (Gene Ontology Causal Activity Model) models. It provides comprehensive annotation guidelines for molecular functions, biological processes, cellular components, and causal relationships following GO Consortium standards.
---

<!--
claude4go: The "This is a copy of the official … https://docs.google.com/…"
notices throughout this skill (in SKILL.md, the README, and every references/
file) are HUMAN source-of-truth pointers. You cannot access Google Docs. Do
not attempt to fetch them, do not treat the local .md as incomplete because
of them, and do not cite the Doc URL as your source. Treat the local markdown
as authoritative for curation.
-->

# GO-CAM Best Practice Skill

This skill provides expert guidance for creating and editing GO-CAM (Gene Ontology Causal Activity Model) models using the barista command-line tool. GO-CAM models represent biological knowledge as networks of causal relationships between molecular activities.

## When to Use This Skill

Use this skill when:
- Creating new GO-CAM models from biological pathway descriptions
- Editing existing GO-CAM models to add activities or relationships
- Validating GO-CAM models against annotation best practices
- Annotating specific molecular function types (transcription factors, receptors, transporters, etc.)
- Representing protein-containing complexes as enablers
- Annotating various molecular functions such as adaptors, carriers, or sequestering proteins
- Adding evidence to support relationships (causal and others)

## Core Guidelines

- **GO-CAM_annotation_guidelines_README.md**: Overview of GO-CAM annotation principles
- **How_to_annotate_complexes_in_GO-CAM.md**: When and how to represent protein complexes
- **Gene_product_identifiers.md**: Choosing the enabler identifier (MOD accession vs UniProtKB)
- **Relation_selection.md**: Causal and contextual relations, with usage for each
- **Evidence_and_evidence_codes.md**: Evidence codes and the ISS ortholog-transfer recipe

## Workflow for Creating a GO-CAM Model

1. **Plan the model**: Identify the biological pathway or process to represent
2. **Identify gene products**: Determine which gene products are involved
3. **Define activities**: For each gene product, determine its molecular function(s)
4. **Add individuals**: Use `barista add-individual` to create activity nodes
5. **Connect activities**: Use `barista add-fact` to create causal relationships
6. **Add context**: Specify inputs, locations, and processes
7. **Add evidence**: Support all facts with evidence codes and references
8. **Validate**: Check against guidelines in `references/` files
9. **Export and review**: Export the model to review its structure


## Core Concepts

## Metadata
- Each model should have a title, a date_created, a contributor and a model state.
- Recommended practices for naming a GO-CAM model is to include: (This is a copy of the official documentation: https://docs.google.com/document/d/1a5YZBJrnJ9LKJxPVpXk62dJJGpHB2b9zH8-xr_Rm1Vs/edit?tab=t.0) 
  1. The GO Biological Process term that best represents the biological process or pathway being modeled.
  2. Additional relevant biological context, such as cells, tissues, specific genes, if not already represented in the GO BP term but helpful for distinguishing models.
  3. Species. If there are two species (host-symbiont), separate the species with a hyphen.
  4. Limit the title length to 60 characters.
     
**Examples:**
  - BMP signaling pathway via dpp-tkv/put (D.mel)
  - 'de novo' AMP biosynthetic process (Mouse)
  - Antifungal innate immune response in the hypodermis via transforming growth factor beta receptor signaling pathway (C. elegans)
  - Mumps-V inhibition of STAT1/STAT3 via DDB1/CUL4A (Human-Paramyxovirus)


### GO-CAM Structure

Every GO-CAM model consists of:
- **Individuals** (nodes): Molecular activities (MF), biological processes (BP), cellular components (CC), inputs, outputs and enablers
- **Facts** (edges): Relationships between individuals, including (but not limited to) causal relations
- **Evidence**: Publications and evidence codes supporting each fact

### Activity Units

An activity unit is the fundamental building block of GO-CAM models:
- **Enabler** the gene product (protein or RNA) or protein-containing complex that mediates the Molecular Function
- **MF (Molecular Function)**: The activity 'enabled' by a gene product or protein-containing complex
- **Context**: Additional information via contextual relations such as 'has input', 'occurs in', 'part of'

### Identifiers: MOD accessions vs UniProtKB
The enabler's identifier depends on the organism: use the **model-organism-database (MOD) accession** for model organisms (MGI, RGD, ZFIN, FB, SGD, WB, PomBase, and others), and **UniProtKB** for human and all other organisms. This is not something a curator should freely specify. See `references/Gene_product_identifiers.md` for the full species list, the MGI double-prefix exception (`MGI:MGI:...`), and how this applies to the ISS `with/from` field.

### Representation of molecular activites enabled by protein-containing complexes
See documentation at How_to_annotate_complexes_in_GO-CAM.md. 

## Annotation Guidelines by Activity Type

The `references/` directory contains detailed guidelines for specific annotation scenarios. Load these files when working with the corresponding activity types:

- DNA-binding_transcription_factor_activity_annotation_guidelines.md (also covers transcription coregulator activity)
- Signaling_receptor_activity_annotation_guidelines.md
- Transporter_activity_annotation_annotation_guidelines.md
- E3_ubiquitin_ligases.md
- Molecular_adaptor_activity.md
- Molecular_carrier_activity.md
- Sequestering_activity.md
- Enzyme_regulator_activity.md
- Chemical_entities_ChEBI.md

## Relations: causal and contextual

Molecular functions are linked to each other with **causal relations**, and to their context (BP, CC, inputs, outputs, temporal phase) with **contextual relations**. Picking the right relation is central to GO-CAM modeling. See `references/Relation_selection.md` for the full tables: all causal relations (direct/indirect, positive/negative, `provides input for`, `removes input for`, `constitutively upstream of`, `causally upstream of`), the small-molecule activator/inhibitor relations, the contextual-relations table, and input/output specification rules.

Key reminders:
- **BP should always be included.** If no relevant BP fits, question whether the model is valid — a standard annotation may be more appropriate.
- Use **direct** regulation only when the mechanism is known and immediate (no intervening activity); otherwise use **indirect**.
- **'has input'** captures the direct target (enzyme substrate, gene regulated by a TF, receptor activated by a ligand, effector activated by a receptor). Only primary inputs/outputs — not chemical-group donors.
- When a MF's `has output` chemical is the `has input` of the next MF, the `provides input for` edge is inferred and is **not** materialized.

## Distinct Individuals for Distinct Roles (do NOT reuse instances)

Every role a molecule plays needs its **own individual**, even when it is the same molecular entity (same UniProtKB ID/MOD ID/GO protein-containing complex ID). In particular, a molecule that is the **`has input`** (RO:0002233) of one activity and the **`enabled by`** (RO:0002333) of another activity must be represented as **two separate
individuals** of that class — never a single shared instance. 

Concrete example: a chaperone folds actin (chaperone activity `has input` actin), and folded actin then `enables` a downstream structural molecule activity. Create two
actin individuals — one as the chaperone's input, a separate one as the enabler of the downstream activity.

Likewise for BPs: each MF, even if it is part of the same BP as another MF, should be modeled as part of distinct instances of the BP. 

**Why this matters:** an activity unit is anchored on its enabler individual, which includes all its context (BP, CC, input, biological phase).
Reusing one individual across multiple roles across different enablers entangles the two activity units so they can no longer be cleanly separated. While the Noctua Graph
Editor still draws every raw triple, the Visual Pathway Editor (VPE) — which reconstructs the GO-CAM activity-flow view centered on enabler individuals — silently **drops
the causal edge** between the two activities when elements of the context are shared. Distinct instances make the activities separable and the causal relations rendered correctly.

**How to build it with barista:** assign a distinct variable per role, e.g.

```bash
# chaperone's input: its own actin instance
barista add-individual -m $MODEL --class UniProtKB:P60709 --assign actin_input --session s
barista add-fact -m $MODEL -s chaperone_mf -t actin_input -p RO:0002233 --session s  # has input

# downstream activity's enabler: a SEPARATE actin instance
barista add-individual -m $MODEL --class UniProtKB:P60709 --assign actin_enabler --session s
barista add-fact -m $MODEL -s actin_mf -t actin_enabler -p RO:0002333 --session s    # enabled by
```

## Evidence

All facts MUST be supported with an evidence code and a reference, and the code must reflect what the cited paper **actually** demonstrates — never over-claim (e.g. IDA for a function that was only inferred). See `references/Evidence_and_evidence_codes.md` for the code-by-code guide (IDA/IMP/IC), the ISS ortholog-transfer recipe (ECO:0000250 + GO_REF:0000024 with the source ortholog's MOD id in `with/from`), and how to handle IBA/IEA annotations fetched from AmiGO.

# Validation Checklist

Before finalizing a GO-CAM model, verify:
- [ ] The most specific available GO term is used for every MF/BP/CC (prefer child terms over parents)
- [ ] No 'obsolete' term is used in the model
- [ ] No terms in the 'go_check_do_not_annotate' gocheck_do_not_annotate <http://purl.obolibrary.org/obo/go#gocheck_do_not_annotate> 
or gocheck_obsoletion_candidate <http://purl.obolibrary.org/obo/go#gocheck_obsoletion_candidate> subsets
- [ ] All activities have appropriate molecular function term
- [ ] Causal relations match the biological mechanism (direct vs. indirect)
- [ ] 'has input' relations specify the correct, direct targets
- [ ] When the output of a MF is the input of the next MF, only 'has ouput' 'and 'has input' relations should be created, not  'provides input for'. 'Provides input for' is only used when the output and input are not specified.
- [ ] No individual is reused across roles: a molecule that is both a 'has input' and an 'enabled by' has a **separate individual for each role** 
(shared instances break VPE causal-edge rendering); as well, each MF should be linked to a different instance of all contextual information (CC, BPs)
- [ ] Cellular components are specified with 'occurs in', and cells and anatomical parts can be added with the 'part of' relation. 
- [ ] Activities are connected to biological processes with 'part of'. 
- [ ] Multiple BPs can be nested using the 'part of' relation. 
- [ ] All facts have supporting evidence, and each evidence code reflects what the cited paper ACTUALLY shows; 
e.g. use ISS + GO_REF:0000024 for a MF/BP/CC inferred from sequence similarity rather than asserting IDA from a paper that does not demonstrate it)
- [ ] Protein-containing complex representation follows guidelines
- [ ] Relation directionality is correct (subject → object)

# Examples

## Example 1: Simple Kinase Activation

```bash
# Create model
barista create-model --title "MAPK signaling example"

# Add receptor activity
barista add-individual --model $MODEL_ID --class GO:0004888 --assign receptor

# Add kinase activity
barista add-individual --model $MODEL_ID --class GO:0004674 --assign kinase

# Connect with causal relationship
barista add-fact --model $MODEL_ID \
  --subject receptor --object kinase \
  --predicate RO:0002629  # directly positively regulates
```

## Example 2: Transcription Factor with Target Gene

```bash
# Add transcription activator activity
barista add-individual --model $MODEL_ID \
  --class GO:0001228 --assign tf_activity  # DNA-binding transcription activator

# Specify the target gene as input
barista add-fact --model $MODEL_ID \
  --subject tf_activity \
  --object <gene-id> \
  --predicate RO:0002233  # has input

# Add the target gene's molecular function
barista add-individual --model $MODEL_ID \
  --class <target-mf> --assign target_activity

# Connect TF to target activity (indirect regulation)
barista add-fact --model $MODEL_ID \
  --subject tf_activity \
  --object target_activity \
  --predicate RO:0002407  # indirectly positively regulates
```

# Tips for Effective GO-CAM Modeling

1. **Start simple**: Begin with core activities and expand incrementally
2. **Use variables**: Assign readable names to individuals for easier reference
3. **Consult examples**: Refer to example models in the guidelines
4. **Be specific**: Use the most specific GO term and relation available
5. **Document evidence**: Always include supporting references
6. **Test first**: Use test server before committing to production
7. **Review guidelines**: Load relevant reference files before annotating complex cases
8. **Think causally**: Focus on how activities mechanistically affect each other

# Common Mistakes to Avoid

- Using obsolete terms
- Using terms from the 'go_check_do_not_annotate' or gocheck_obsoletion_candidate subsets
- Using 'has input' to specify a ligand for a receptor (should use causal relation instead)
- Using direct regulation when the mechanism is multi-step (use indirect)
- Forgetting to specify cellular location with 'occurs in'
- Creating activities without connecting them to biological processes
- Missing evidence codes and references
- Using generic terms when specific child terms are available
- Incorrect causal relation directionality
- Reusing one individual for both a 'has input' and an 'enabled by' role (create a distinct individual per role, even for the same molecular entity — see "Distinct Individuals for Distinct Roles")
- Likewise for BPs: each MF should be connected to a distinct instance of a BP
- Capturing chemicals that are not primary inputs or outputs
- Choosing an evidence code for convenience rather than matching what the paper demonstrates (over-claiming IDA for functions that are actually known/inferred; double check what data the paper shows)
- Leaving an activity (MF individual) with no `enabled_by` (Noctua validation error)
- Adding a `has output` when the `has input` is a gene product (use `directly regulates` instead)
- Using UniProtKB for a model-organism gene product (use the MOD id: MGI/RGD/ZFIN/...); human is the exception
- Representing one compound with two different CHEBI ids across a handoff (breaks the chain)
- Placing a reaction byproduct on the wrong activity (e.g. the fatty acid from a ceramidase on a neighbouring chaperone)
- Over-claiming IDA for a function the paper does not demonstrate (use ISS with the right reference or IC)
- Citing a bare DOI instead of a PMID

# Getting Help

- Check relevant guideline files in `references/` directory
- Search for similar examples using `barista list-models`
- Export and examine well-annotated models for patterns
- Consult the GO Consortium documentation
- Review the noctua-py documentation at https://github.com/geneontology/noctua-py

# Reference Files Summary

Load these files from the `references/` directory as needed:

Cross-cutting references (apply to most models):
- GO-CAM_annotation_guidelines_README.md
- How_to_annotate_complexes_in_GO-CAM.md
- Gene_product_identifiers.md
- Relation_selection.md
- Evidence_and_evidence_codes.md

Activity-type guidelines (load when working with that activity type):
- DNA-binding_transcription_factor_activity_annotation_guidelines.md (also covers transcription coregulator activity)
- E3_ubiquitin_ligases.md
- Molecular_adaptor_activity.md
- Molecular_carrier_activity.md
- Sequestering_activity.md
- Enzyme_regulator_activity.md
- Signaling_receptor_activity_annotation_guidelines.md
- Transporter_activity_annotation_annotation_guidelines.md
