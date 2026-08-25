# Annotation guidelines for transporter activity
**_Note : This is a copy of the official [MF annotation guidelines for GO-CAM](https://docs.google.com/document/d/186PR8Ml7JpudB8q23-enpCbXhsLpBkuivXV79Agr15w/edit?tab=t.pfmzxkwwlwc6#heading=h.xkfnecvy0xu7)_**
----

## Activity unit for a transmembrane transporter:

* **MF**: 'enables' a child of transmembrane transporter activity ([GO:0022857](https://amigo.geneontology.org/amigo/term/GO:0022857))
* **Context:**
  + The movement of the small molecule substrate is represented by:
    - small molecule (ChEBI) + 'input of' + the start location of the small molecule, captured with the relation 'located in'
    - the transporter activity + 'has output' the small molecule (ChEBI) + the end location of the small molecule, captured with the relation 'located in'
  + **BP**: 'part of' the BP in which this transporter activity participates
  + **CC**: 'occurs in' a child of membrane ([GO:0016020](https://amigo.geneontology.org/amigo/term/GO:0016020)), e. g.: lysosomal membrane ([GO:0005765](https://amigo.geneontology.org/amigo/term/GO:0005765)).

**Example:** [**SLC17A9 transports ATP to the lysosomal lumen**](http://noctua.geneontology.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A6a4c244800004928)
