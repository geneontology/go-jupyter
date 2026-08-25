# Annotation guidelines for molecular carrier activity
**_Note : This is a copy of the official [MF annotation guidelines for GO-CAM](https://docs.google.com/document/d/186PR8Ml7JpudB8q23-enpCbXhsLpBkuivXV79Agr15w/edit?tab=t.0)_**
____

## Relevant definitions
**Molecular carrier activity definition:** A molecular carrier activity is the activity of directly binding to a specific ion or molecule and delivering it either to an acceptor molecule or to a specific location. A carrier moves with the substrate it carries, contrary to a transporter.

## Activity unit for a molecular carrier:

* **MF**: 'enables' molecular carrier activity ([GO:0140104](https://amigo.geneontology.org/amigo/term/GO:0140104)) or a child
* **Context:**
  + The relation between a transported molecule and its carrier is 'has input'. The carrier and the small molecule are linked with the 'has output' relation, so that the small molecule can be the input for the next reaction.
  + **BP**: 'part of' the process in which the molecule using the small molecule participates, or 'part of' regulation of the process, if the carrier is a regulator (rate-limiting for the execution of the process)
  + **CC**: 'occurs in' the cellular location where the activity takes place.
  + The **causal relation** between the molecular carrier and the protein it delivers the substrate to is 'provides input for', which is usually captured as 'has output' on the molecular carrier activity unit, and 'has input' in the activity unit of the acceptor. 

**Example:** [**LPS is carried to its receptor by CD14**](http://noctua.geneontology.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A6a4c244800004789)
