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
- Representing complexes, adaptors, carriers, or sequestering proteins
- Adding evidence to support causal relationships

## Core Concepts

### GO-CAM Structure

Every GO-CAM model consists of:
- **Individuals** (nodes): Molecular activities (MF), biological processes (BP), or cellular components (CC)
- **Facts** (edges): Relationships between individuals, including causal relations
- **Evidence**: Publications and evidence codes supporting each fact

### Activity Units

An activity unit is the fundamental building block of GO-CAM models:
- **MF (Molecular Function)**: The activity 'enabled' by a gene product
- **Context**: Additional information via relations like 'has input', 'occurs in', 'part of'
- **Causal Relations**: How this activity affects other activities

## Annotation Guidelines by Activity Type

The `references/` directory contains detailed guidelines for specific annotation scenarios. Load these files when working with the corresponding activity types:

### Core Guidelines

- **GO-CAM_annotation_guidelines_README.md**: Overview of GO-CAM annotation principles
- **How_to_annotate_complexes_in_GO-CAM.md**: When and how to represent protein complexes

### Specific Molecular Function Types

- DNA-binding_transcription_factor_activity_annotation_guidelines.md
- Signaling_receptor_activity_annotation_guidelines.md
- Transporter_activity_annotation_annotation_guidelines.md
- E3_ubiquitin_ligases.md
- Molecular_adaptor_activity.md
- Molecular_carrier_activity.md
- Protein_sequestering_activity.md
- Transcription_coregulator_activity.md

## Common Patterns and Best Practices

### Causal Relationship Selection

Choose the appropriate causal relation:

- **directly positively regulates**: Direct activation (e.g., ligand → receptor, kinase → substrate)
- **directly negatively regulates**: Direct inhibition
- **indirectly positively regulates**: Multi-step activation (e.g., transcription factor → target gene activity)
- **indirectly negatively regulates**: Multi-step inhibition

### Input Specification

Use 'has input' to specify:
- The substrate of an enzyme
- The gene regulated by a transcription factor
- The receptor activated by a ligand
- The effector protein activated by a receptor

**Important**: For receptors, 'has input' specifies the downstream effector, NOT the ligand.

### Complex Representation

Three approaches based on knowledge:

1. **Subunit with activity is known**: Represent the specific protein, not the complex
2. **Subunit with activity unknown**: Use the GO complex term
3. **Activity shared by multiple subunits**: Represent all relevant subunits

### Context Annotations

Always include:
- **CC (Cellular Component)**: Use 'occurs in' to specify location
- **BP (Biological Process)**: Use 'part of' to connect to larger biological processes
- **Evidence**: Support all facts with evidence codes and references

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

## Reference File Usage Strategy

When annotating, identify the molecular function type involved and load the corresponding reference file from the list above.

## Validation Checklist

Before finalizing a GO-CAM model, verify:
- [ ] All activities have appropriate molecular function terms
- [ ] Causal relations match the biological mechanism (direct vs. indirect)
- [ ] 'has input' relations specify the correct targets
- [ ] Cellular components are specified with 'occurs in'
- [ ] Activities are connected to biological processes with 'part of'
- [ ] All facts have supporting evidence
- [ ] Complex representation follows guidelines
- [ ] Relation directionality is correct (subject → object)

## Examples

### Example 1: Simple Kinase Activation

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
  --predicate RO:0002413  # directly positively regulates
```

### Example 2: Transcription Factor with Target Gene

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

## Tips for Effective GO-CAM Modeling

1. **Start simple**: Begin with core activities and expand incrementally
2. **Use variables**: Assign readable names to individuals for easier reference
3. **Consult examples**: Refer to example models in the guidelines
4. **Be specific**: Use the most specific GO term and relation available
5. **Document evidence**: Always include supporting references
6. **Test first**: Use test server before committing to production
7. **Review guidelines**: Load relevant reference files before annotating complex cases
8. **Think causally**: Focus on how activities mechanistically affect each other

## Common Mistakes to Avoid

- Using 'has input' to specify a ligand for a receptor (should use causal relation instead)
- Using direct regulation when the mechanism is multi-step (use indirect)
- Forgetting to specify cellular location with 'occurs in'
- Creating activities without connecting them to biological processes
- Missing evidence codes and references
- Using generic terms when specific child terms are available
- Incorrect causal relation directionality

## Getting Help

- Check relevant guideline files in `references/` directory
- Search for similar examples using `barista list-models`
- Export and examine well-annotated models for patterns
- Consult the GO Consortium documentation
- Review the noctua-py documentation at https://github.com/geneontology/noctua-py

## Reference Files Summary

Load these files from the `references/` directory as needed:

- How_to_annotate_complexes_in_GO-CAM.md
- How_to_annotate_molecular_adaptors.md
- How_to_annotate_sequestering_proteins.md
- DNA-binding_transcription_factor_activity_annotation_guidelines.md
- Signaling_receptor_activity_annotation_guidelines.md
- Transporter_activity_annotation_annotation_guidelines.md
- E3_ubiquitin_ligases.md
- Molecular_adaptor_activity.md
- Molecular_carrier_activity.md
- Protein_sequestering_activity.md
- Transcription_coregulator_activity.md
