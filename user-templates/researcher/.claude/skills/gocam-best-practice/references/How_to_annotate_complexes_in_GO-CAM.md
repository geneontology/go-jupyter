# Annotation guidelines for protein complexes
**_Note : This is a copy of the official [MF annotation guidelines for GO-CAM](https://docs.google.com/document/d/1a5YZBJrnJ9LKJxPVpXk62dJJGpHB2b9zH8-xr_Rm1Vs/edit?tab=t.0#heading=h.s5hxf4l9yow)_**
----

Protein-containing complexes can be captured in three different ways, depending on how their member proteins enable an activity:

## 1. **The subunit that carries out the molecular activity is known:**
In this case, the specific protein is the enabler, not the complex. An example is [ubiquitin ligase subunits](http://noctua.geneontology.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A69a0c46f00002912). Link the enabler gene product to the GO complex term with a 'part of' (BFO:0000050) relation. Curators should always strive to assign an MF to an individual gene product. If a MF can be assigned to an individual member of the complex, do not use the whole complex as the enabler, use the gene product.

### Guideline: `part of <complex>` attaches to the enabler, not the molecular function

**Rule.** When representing a protein-containing complex via the
*subunit-with-activity-known* pattern, the `part of` (BFO:0000050) relation to
the complex GO term MUST be placed on the **enabler** (the gene product
individual), never on the molecular function individual.

**Rationale.** A molecular function is an activity, not a physical entity, so it
cannot be a component (`part of`) of a complex. Only a gene product can be a
subunit of a complex.

**How to build it.**

- Correct:  `enabler_gene_product —[part of]→ complex_term`
- Wrong:    `molecular_function —[part of]→ complex_term`

**Contrast with other context relations.** The biological-process (`part of` BP)
and cellular-component (`occurs in` CC) context relations DO attach to the
molecular function individual. Only the complex-membership `part of` moves to
the enabler.

| Context              | Relation                 | Attaches to             |
|----------------------|--------------------------|-------------------------|
| Biological process   | `part of` (BFO:0000050)  | MF individual           |
| Cellular component   | `occurs in` (BFO:0000066)| MF individual           |
| **Complex membership** | **`part of` (BFO:0000050)** | **enabler (gene product)** |

## 2. **The subunit which carries the molecular activity is not known:**
In this case, the protein complex is the enabler, represented by the GO ID for the complex.
E.g.: Ragulator complex (GO:0071986): Ragulator is composed of the membrane anchor subunit LAMTOR1, LAMTOR2, LAMTOR3, LAMTOR4 and LAMTOR5. In this example LAMTOR1 activity is known (protein-membrane adaptor activity) but the protein that carries the guanyl-nucleotide exchange factor activity is not known, therefore we use the complex ID from GO in this case. See [example model](http://noctua.geneontology.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A6a4c244800001895).

## 3. **The activity is shared by multiple subunits** (aka "emerging function"):
This case represents functions that none of the subunits is capable of accomplishing physiologically on its own, or cases in which the active site and/or the ligand or cofactor binding sites are shared between multiple subunits (see the ['membrane attack complex' example](http://noctua.geneontology.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A6a4c244800002109)). In this case, the GO complex term is the enabler and individual subunits are captured with the 'has part' (BFO:0000051) relation.

### Guideline: the GO complex enables the activity and `has part` its subunits

**Rule.** In the *emerging-function* pattern, the GO protein-complex term is the
enabler of the molecular function, and each contributing subunit gene product is
attached to the complex individual with a `has part` (BFO:0000051) relation.

**Rationale.** No single subunit can carry out the activity on its own — the
active site and/or the ligand/cofactor-binding sites are distributed across
subunits — so the activity is a property of the assembled complex, not of any
one member. `has part` records which gene products make up that complex.

**How to build it.**

- Enabler:   `molecular_function —[enabled by]→ complex_term`
- Subunits:  `complex_term —[has part]→ subunit_gene_product`  (one per subunit)

**Contrast with Case 1.** In Case 1 the *gene product* is the enabler and is
`part of` the complex; here the *complex* is the enabler and `has part` its
subunits. The relation direction is reversed because the enabler is different.
