# Annotation guidelines for enzyme regulator activity (activator and inhibitor)
**_Note : This is a copy of the official [MF annotation guidelines for GO-CAM](https://docs.google.com/document/d/186PR8Ml7JpudB8q23-enpCbXhsLpBkuivXV79Agr15w/edit?tab=t.7jrbx26oudmd#heading=h.8i7uscfol0rp)_**
----

**Scope:** proteins that regulate the activity of an enzyme (or another molecular function) by **direct, non-covalent binding**, *without* covalently modifying the target. This is the key contrast with covalent modifiers such as kinases and phosphatases, which use a catalytic MF instead. The GO terms below carry an explicit usage note: use them only when the regulator directly interacts with the target but does not result in a covalent modification.

# Activity unit for an enzyme regulator:

* **MF**: 'enables' the appropriate regulator term:
  + enzyme inhibitor activity ([GO:0004857](https://amigo.geneontology.org/amigo/term/GO:0004857)) — reduces a catalytic activity
  + enzyme activator activity ([GO:0008047](https://amigo.geneontology.org/amigo/term/GO:0008047)) — increases a catalytic activity
  + when the regulated target is **not** an enzyme (e.g. a receptor or transporter), use the broader molecular function inhibitor activity ([GO:0140678](https://amigo.geneontology.org/amigo/term/GO:0140678)) or molecular function activator activity ([GO:0140677](https://amigo.geneontology.org/amigo/term/GO:0140677))
* **Context:**
  + The relation between the regulator activity and the **enzyme (or protein) whose activity it regulates** is 'has input'
  + **BP**: 'part of' regulation of the process in which the target participates (negative regulation for an inhibitor, positive for an activator)
  + **CC**: 'occurs in' the location where the activity occurs
  + The causal relation between the regulator activity and the target activity is 'directly negatively regulates' ([RO:0002630](https://www.ebi.ac.uk/ols4/ontologies/ro/properties?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0002630)) for an inhibitor, or 'directly positively regulates' ([RO:0002629](https://www.ebi.ac.uk/ols4/ontologies/ro/properties?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0002629)) for an activator — direct, because there is a direct physical interaction between the two proteins.

## Small-molecule regulators

If the regulator is a **small molecule** (ChEBI) rather than a protein, it has no molecular function of its own. Link it directly to the regulated activity with 'is small molecule activator of' ([RO:0012005](https://www.ebi.ac.uk/ols4/ontologies/ro/properties?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0012005)) or 'is small molecule inhibitor of' ([RO:0012006](https://www.ebi.ac.uk/ols4/ontologies/ro/properties?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FRO_0012006)) — see `Relation_selection.md`.

## Contrast with related patterns
- **Covalent modifiers** (kinases, phosphatases, proteases, ubiquitin ligases) regulate by modifying the target; they use a catalytic MF, not enzyme regulator activity.
- **Sequestering activity** removes a target from where it acts (rather than binding its active site to modulate catalysis) — see `Sequestering_activity.md`.

**Example:** [**GDP-mannose biosynthetic process (Dmel) — GMPPA inhibits GMPPB**](http://noctua.geneontology.org/workbench/noctua-visual-pathway-editor/?model_id=gomodel%3A662af8fa00000838). GMPPA enables an enzyme inhibitor activity that is activated by the pathway's own output (GDP-alpha-D-mannose), forming a feedback loop.
