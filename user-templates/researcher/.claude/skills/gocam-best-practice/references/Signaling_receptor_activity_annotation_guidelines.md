# Annotation guidelines for signaling receptor & coreceptor activity
**_Note : This is a copy of the official [MF annotation guidelines for GO-CAM](https://docs.google.com/document/d/186PR8Ml7JpudB8q23-enpCbXhsLpBkuivXV79Agr15w/edit?tab=t.ymi8memuijla)_**
----

## Relevant definitions
**Signaling receptor activity definition:** A signaling receptor receives a signal and transmits it in the cell to initiate a change in cell activity. A signal is a physical entity or change in state (for example light, see photoreceptor activity [GO:0009881](https://amigo.geneontology.org/amigo/term/GO:0009881)) that is used to transfer information in order to trigger a response.

**Receptor activation by a ligand is represented differently in GO-CAM depending on whether the ligand is (1) a protein (i. e., encoded by a gene) or (2) a small molecule.**

## 1. Protein ligand-activated signaling receptor

### 1.1 Activity unit for a receptor ligand

* **MF**: a ligand 'enables' receptor ligand activity ([GO:0048018](https://amigo.geneontology.org/amigo/term/GO:0048018)) or a child
* **Context:**
  + The ligand 'has input' its target receptor, and not the receptor 'has input' the ligand. This is to keep the causal flow, in which the ligand acts on the receptor.
  + **BP**: 'part of' the process in which the ligand participates, usually a child of signal transduction ([GO:0007165](https://amigo.geneontology.org/amigo/term/GO:0007165))
  + **CC**: 'occurs in' the location of the ligand:
    - extracellular ligands: extracellular region ([GO:0005576](https://amigo.geneontology.org/amigo/term/GO:0005576))
    - membrane-bound ligands: plasma membrane ([GO:0005886](https://amigo.geneontology.org/amigo/term/GO:0005886))
  + The causal relation between the ligand activity and the receptor activity is 'directly positively regulates'.

### 1.2 Activity unit for a signaling receptor activity

* **MF**: a signaling receptor 'enables' signaling receptor activity ([GO:0038023](https://amigo.geneontology.org/amigo/term/GO:0038023)) or a child
* **Context:**
  + The input (target) of the receptor is the effector protein it regulates, for example a molecular adaptor, captured with the 'has input' relation. Note that the input (target) of the receptor is NOT its ligand.
  + **BP**: 'part of' the same BP/signal transduction pathway as the ligand
  + **CC**: transmembrane receptors: 'occurs in' plasma membrane ([GO:0005886](https://amigo.geneontology.org/amigo/term/GO:0005886))
  + The causal relation between the MF of the receptor and the MF of its target is 'directly positively regulates'.

**Example:** [**Model for protein-activated signaling receptor**](http://noctua.geneontology.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A6482692800000931)

## 2. Activity unit for small molecule-activated signaling receptor activity

Since small molecules are not annotated in GO, a small molecule ligand does not have a molecular function. Instead, the ligand and the receptor activity are linked by the causal relation 'is small molecule activator'. It is also possible to annotate an inhibitory ligand using the relation 'is small molecule inhibitor'.

The receptor's function, input, and contextual (BP and CC) relations are the same as for protein ligand-activated receptor activity.

**Example:** [**Model for a small molecule-activated signaling receptor activity**](http://noctua.geneontology.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A69a0c46f00002718)

## 3. Receptor acting with a coreceptor
This is common in immune receptors. The typical sequence of events is that the ligand binds the signaling receptor, which signals to the co-receptor to activate its downstream effector (such as a protein kinase).

The activity unit for a signaling coreceptor is:

* **MF**: coreceptor activity ([GO:0015026](https://amigo.geneontology.org/amigo/term/GO:0015026))
* **Context:**
  + The signaling receptor 'has input' the downstream coreceptor it acts on, NOT the ligand.
  + The input (target) of the coreceptor is the downstream effector protein. 
  + **BP**: 'part of' the BP in which the signaling receptor is involved, usually a child of signal transduction ([GO:0007165](https://amigo.geneontology.org/amigo/term/GO:0007165))
  + **CC**: transmembrane receptors: 'occurs in' plasma membrane ([GO:0005886](https://amigo.geneontology.org/amigo/term/GO:0005886))
  + The causal relation between the MF of the signaling receptor and the MF of its coreceptor is 'directly positively regulates'.

**Example:** [**Model for a receptor-coreceptor system**](http://noctua.geneontology.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A69a0c46f00003789): Interleukin-2 (IL2), a cytokine, activates its receptor, interleukin-2 receptor A (IL2RA). IL2RA directly positively regulates (activates) the IL2RB coreceptor, which phosphorylates and positively regulates JAK13.
