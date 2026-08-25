# Selecting relations in GO-CAM (causal and contextual)

Molecular functions are linked to each other via **causal relations**, and to their context (biological process, cellular component, inputs, outputs, temporal phase) via **contextual relations**. This document lists both.

## Causal Relationship Selection
See https://wiki.geneontology.org/Annotation_Relations for original documentation.

Molecular functions are linked to each other via causal relations. Choose the appropriate causal relation:

Relation | Usage |
|---|---|
[causally upstream of, negative effect](https://www.ebi.ac.uk/ols4/ontologies/ro/properties?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0002305) | Links two activities when the upstream activity has a negative causal effect (decreasing or inhibiting) on the downstream activity but the mechanism is not known. |
[causally upstream of, positive effect](https://www.ebi.ac.uk/ols4/ontologies/ro/properties?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0002304) | Links two activities when the upstream activity has a positive causal effect (increasing or activating) on the downstream activity but the mechanism is not known. |
[provides input for](https://www.ebi.ac.uk/ols4/ontologies/ro/properties?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0002413) | Links two successive activities when the product (output) of the upstream activity is the substrate (input) for the downstream activity, and the product is a macromolecule (i.e. DNA, RNA, protein). |
[removes input for](https://www.ebi.ac.uk/ols4/ontologies/ro/properties?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0012010) | Links two activities when the upstream activity has a negative causal effect (decreasing or inhibiting) on the downstream activity and the two activities act on or modify the same molecular target at the same site(s). |
[constitutively upstream of](https://www.ebi.ac.uk/ols4/ontologies/ro/properties?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0012009) | Links two activities when the upstream activity is required for the downstream activity, but does not regulate the downstream activity. |
[directly negatively regulates](https://www.ebi.ac.uk/ols4/ontologies/ro/properties?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0002630) | Links two activities when the upstream activity has a negative causal effect (decreasing or inhibiting) on an immediately downstream activity. Immediately means there is no intervening activity. The mechanism by which the upstream activity controls the downstream activity must be known. |
[directly positively regulates](https://www.ebi.ac.uk/ols4/ontologies/ro/properties?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0002629) | Links two activities when the upstream activity has a positive causal effect (increasing or activating) on an immediately downstream activity. Immediately means there is no intervening activity. The mechanism by which the upstream activity controls the downstream activity must be known. |
[indirectly negatively regulates](https://www.ebi.ac.uk/ols4/ontologies/ro/properties?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0002409) | Links two activities when the upstream activity has a negative regulatory effect (decreasing or inhibiting) on the downstream activity via a larger process (e.g. proteasome-mediated protein degradation) that is reused in many contexts and the curator does not want to reproduce that process in the GO-CAM. The mechanism by which the upstream activity controls the downstream activity must be known. |
[indirectly positively regulates](https://www.ebi.ac.uk/ols4/ontologies/ro/properties?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0002407) | Links two activities when the upstream activity has a positive regulatory effect (increasing or activating) on the downstream activity via a larger process (e.g. transcription) that is reused in many contexts and the curator does not want to reproduce that process in the GO-CAM. The mechanism by which the upstream activity controls the downstream activity must be known. |

Small molecules (from ChEBI) can be activators or inhibitors of MFs. In these cases, the relations are:
Relation | Usage|
|---|---|
[is small molecule activator of](https://www.ebi.ac.uk/ols4/ontologies/ro/properties?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0012005) | Links a small molecule and an activity, when the small molecule activates the activity. |
[is small molecule inhibitor of](https://www.ebi.ac.uk/ols4/ontologies/ro/properties?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0012006) | Links a small molecule and an activity, when the small molecule inhibits the activity. |

Special case: inference chain between 'has ouput' and 'has input'
- When a MF has output a chemical, which itself is the input of the next relation, the causal relation 'provides input for' in inferred from this pattern. However, in GO-CAM, the redundant 'provides input for' relation is not materialized.

## Contextual Relations Selection

The following context can be included
- **BP (Biological Process)**: Use 'part of' to connect the MF to the BP. 'Larger' biological processes can be further nested using the 'part of' relation; for example, Wnt receptor activity is 'part of' Wnt signaling pathway, which is 'part of' imaginal disc-derived wing morphogenesis. BP should always be included; if no relevant BP is identified, the validity of the model should be questioned; perhaps a standard annotation is more appropriate.
- **CC (Cellular Component)**: Use 'occurs in' to specify GO cellular location. If known, the CC can be nested under a cell type from the Cell Type ontology or an anatomical structure from Uberon, using the 'part of' relation.
- **Happens during**: GO biological phase, or a term frome a developmental stage ontology.
- **Evidence**: All facts (relations) MUST be supported with evidence codes and references.

The following table shows how various individuals can be connected to provide contexr:
| Link | Relation | Description |
|------|----------|-------------|
| Molecular Function to Biological Process | part of | Links a Molecular Function to a Biological Process when the Molecular Function is an integral part of the Biological Process. |
| Molecular Function to Anatomical Entity | occurs in | Links a Molecular Function to the anatomical entity, e.g. a GO cellular component or a cell or tissue type, where it occurs. |
| Molecular Function to Input | has input | Links a Molecular Function to a specific molecular target acted upon. |
| Molecular Function to Output | has output | Links a Molecular Function to the specific molecular output produced by the reaction or process. |
| Molecular Function to Temporal Phase | happens during | Links a Molecular Function to a biological phase or stage, e.g. M phase or L1 larval stage when it occurs. |
| Biological Process to Biological Process | part of | Links a Biological Process to another Biological Process, e.g. MAPK cascade part of a receptor signaling pathway or a receptor signaling pathway part of a development process, of which it is an integral part. |
| Anatomical Entity to Anatomical Entity | part of | Links anatomical entities to one another to refine the location of the entity, e.g. a nucleus may be part of an intestinal epithelial cell. |
| Protein Containing Complex to Gene Product | has part | Links protein containing complexes to the genes or gene products that are members of that complex. |

#### Input Specification

Use 'has input' to specify:
- The substrate of an enzyme
- The gene regulated by a transcription factor
- The receptor activated by a ligand
- The effector protein activated by a receptor
- Only primary inputs and outputs of a reactions should be used. Chemical groups donors are usually not primary inputs/outputs.
- Proteins can be used are inputs when they are covalently modified, such as with a phosphate group by a protein kinase, but for proteins, not output is captured.
