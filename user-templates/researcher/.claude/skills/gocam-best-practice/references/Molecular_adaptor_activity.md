# Annotation guidelines for molecular adaptor activity
**_Note : This is a copy of the official [MF annotation guidelines for GO-CAM](https://docs.google.com/document/d/186PR8Ml7JpudB8q23-enpCbXhsLpBkuivXV79Agr15w/edit?tab=t.kdbkq1kgzsyz#heading=h.gjdgxs)_**
____
## Relevant definitions
**Molecular adaptor activity definition:** A molecular adaptor activity is the binding activity of a molecule that brings together two or more molecules through a selective, non-covalent, often stoichiometric interaction, permitting those molecules to function in a coordinated way.

## Activity unit for a molecular adaptor:

* **MF**: 'enables' molecular adaptor activity ([GO:0060090](https://amigo.geneontology.org/amigo/term/GO:0060090)) or a child
* **Context:**
  + The relation between the adaptor activity and the two (or more) molecules it brings together is 'has input'
  + **BP**: 'part of' the BP in which the adaptor participates
  + **CC**: 'occurs in' the cellular location where the activity takes place.

The relation between the adaptor and the proteins it adapts can be 'directly positively regulates', 'constitutively upstream of', or 'provides input for', depending if the activity of the adaptor is regulatory.

**Example 1:** [**TYROBP acts as an adaptor between a receptor and a downstream effector**](http://noctua.geneontology.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A633b013300001197)

SIGLEC1 recognizes and endocytoses virions, which leads to activation of the TYROBP molecular adaptor, which recruits PTPN11. The scaffolding activity of PTPN11 is activated by TYROBP.

**Example 2:** [**An adaptor that brings together an enzyme and its substrate**](http://noctua.geneontology.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A636d9ce800001192)


