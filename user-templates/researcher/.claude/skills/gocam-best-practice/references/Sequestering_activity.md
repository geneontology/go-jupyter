# Annotation guidelines for molecular sequestering activity
**_Note : This is a copy of the official [MF annotation guidelines for GO-CAM](https://docs.google.com/document/d/186PR8Ml7JpudB8q23-enpCbXhsLpBkuivXV79Agr15w/edit?tab=t.detiv7ampq5e#heading=h.xkfnecvy0xu7)_**
----

## Relevant definitions
**Molecular sequestering activity definition:** A sequestering activity is the binding to a specific molecule to prevent it from interacting with other partners or to inhibit its localization to the area of the cell or complex where it is active.

## Activity unit for a molecular sequestering activity:

* **MF**: 'enables' molecular sequestering activity ([GO:0140313](https://amigo.geneontology.org/amigo/term/GO:0140313)) or a child. The most commonly used child is protein sequestering activity ([GO:0140311](https://amigo.geneontology.org/amigo/term/GO:0140311)).
* **Context:**
  + The relation between the protein that acts to sequester and its target is 'has input'
  + **BP**: 'part of' negative regulation of the BP in which the target protein participates.
  + **CC**: 'occurs in' the location where the activity occurs.
  + The causal relation between the sequestering activity and the activity of the protein it inhibits is 'directly negatively regulates', because there is a direct interaction between the two proteins.

**Example:** [**Sequestering activity of CAV1 negatively regulates TLR4 signaling**](http://noctua.geneontology.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A6a4c244800004950)


