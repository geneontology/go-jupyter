# Annotation guidelines for DNA-binding transcription factor activity
**_Note : This is a copy of the official [MF annotation guidelines for GO-CAM](https://docs.google.com/document/d/186PR8Ml7JpudB8q23-enpCbXhsLpBkuivXV79Agr15w/edit?tab=t.3a4daa4ci29e#heading=h.xkfnecvy0xu7)_**
----
## Relevant definitions
* **DNA-binding transcription factor activity definition:** A DNA-binding transcription factor activity is described as a transcription regulator activity that modulates transcription of gene sets via selective and non-covalent binding to a specific double-stranded genomic DNA sequence (sometimes referred to as a motif) within a cis-regulatory region. Regulatory regions include promoters (proximal and distal) and enhancers. Genes are transcriptional units, and include bacterial operons.

* **Transcription coregulator activity definition:** A transcription regulator activity that modulates the transcription of specific gene sets via binding to a DNA-binding transcription factor at a specific genomic locus, either on its own or as part of a complex. Coregulators often act by altering chromatin structure and modifications. For example, one class of transcription coregulators modifies chromatin structure through covalent modification of histones. A second class remodels the conformation of chromatin in an ATP-dependent fashion. A third class modulates interactions of DNA-bound DNA-binding transcription factors with other transcription coregulators.

## Activity unit for a eukaryotic DNA-binding transcription factor activity

### DNA-binding transcription factor activity - Single transcription target

The activity unit for a eukaryotic DNA-binding transcription factor is:

* **MF:** 'enables' a child of DNA binding transcription factor activity, RNA polymerase, II-specific ([GO:0000981](https://amigo.geneontology.org/amigo/term/GO:0000981)):
  + DNA-binding transcription activator activity, RNA polymerase, II-specific ([GO:0001228](https://amigo.geneontology.org/amigo/term/GO:0001228))
  + DNA-binding transcription repressor activity, RNA polymerase II-specific ([GO:0001227](https://amigo.geneontology.org/amigo/term/GO:0001227))
* **Context:**
  + The relation between the DNA-binding transcription factor activity and the gene it regulates is 'has input'
  + **BP:** 'part of' regulation of the BP in which the target participates (if known).
  + **CC:** 'occurs in' nucleus ([GO:0005634](https://amigo.geneontology.org/amigo/term/GO:0005634))
  + The causal relation between the transcription factor activity and the activity of its target gene is: ‘indirectly positively regulates’ or 'indirectly negatively regulates’, since there are several steps between the activation of transcription and the activity of the target protein, including the production of a messenger RNA that is translated into a protein, i. e the regulator does not directly interact with the protein it regulates.

**Example single target:** [**FOXO3 regulation of G6PC1**](http://noctua.geneontology.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A645d887900001840)

### DNA-binding transcription factor activity - Multiple transcription targets

In cases where transcription factor regulates multiple target genes, a separate activity unit is captured for each transcriptional target.

**Example multiple targets:** [**FOXO3 regulation of G6PC1 and Pck1**](http://noctua.geneontology.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A645d887900001840)


### Nuclear receptor activity and ligand-activated transcription factor activity

* Nuclear receptors are positively regulated by a ligand, usually a small molecule term from ChEBI.
* The activity unit for a nuclear receptor is:
  + **MF**: nuclear receptor activity ([GO:0004879](https://amigo.geneontology.org/amigo/term/GO:0004879)) (a child of transcription factor activity)
  + **Context:** the causal relation between the small molecule and the nuclear receptor is ‘is small molecule activator of’.
  + Other data are captured the same way as for other transcription factors (see above).

**Example:** [**Model for nuclear receptor annotation**](http://noctua.geneontology.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A6482692800001263)

## Transcription coregulator activity
* **MF:** 'enables' a child of transcription coregulator activity ([GO:0003712](https://amigo.geneontology.org/amigo/term/GO:0003712)):
  * transcription coactivator activity ([GO:0003713](https://amigo.geneontology.org/amigo/term/GO:0003713))
  * transcription corepressor activity ([GO:0003714](https://amigo.geneontology.org/amigo/term/GO:0003714))
* **Context:**
  + The relation between the coregulator activity and the transcription factor regulated is 'has input'
  + **BP:** 'part of' regulation of the BP in which the target participates (if known).
  + **CC:** 'occurs in' nucleus ([GO:0005634](https://amigo.geneontology.org/amigo/term/GO:0005634))
  + The causal relation between the transcription coregulator activity and the transcription factor activity unit is directly positively regulates or directly negatively regulates.
  + There should not be a causal relation between the coregulator activity and the target gene of the transcription factor.

## Activity unit for a prokaryotic DNA-binding transcription factor activity
This is similar to how eukaryotic DbTFs are captured, but the terms are slightly different:
* **MF:** 'enables' a child of DNA binding transcription factor activity ([GO:0003700](https://amigo.geneontology.org/amigo/term/GO:0003700)):
  + DNA-binding transcription activator activity ([GO:0001216](https://amigo.geneontology.org/amigo/term/GO:0001216))
  + DNA-binding transcription repressor activity ([GO:0001217](https://amigo.geneontology.org/amigo/term/GO:0001217))
* **Context:**
  + The relation between the DNA-binding transcription factor activity and the gene it regulates is 'has input'
  + **BP:** 'part of' regulation of the BP in which the target participates (if known).
  + **CC:** 'occurs in' cytosol ([GO:0005829](https://amigo.geneontology.org/amigo/term/GO:0005829))
  + The causal relation between the transcription factor activity and the activity of its target gene is: ‘indirectly positively regulates’ or 'indirectly negatively regulates’, since there are several steps between the activation of transcription and the activity of the target protein, including the production of a messenger RNA that is translated into a protein, i. e the regulator does not directly interact with the protein it regulates.
