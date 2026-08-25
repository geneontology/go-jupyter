# Choosing chemical entity (ChEBI) terms in GO-CAM

**_Note : This is a copy of the official [MF annotation guidelines for GO-CAM](https://docs.google.com/document/d/1a5YZBJrnJ9LKJxPVpXk62dJJGpHB2b9zH8-xr_Rm1Vs/edit?tab=t.247fv66619s)_**
----

Small molecules enter a GO-CAM as **individuals** — a `has input` / `has output` of an
activity, or via `is small molecule activator of` / `is small molecule inhibitor of` a
molecular function (see `Relation_selection.md` and `Enzyme_regulator_activity.md`). A
small molecule is **not an enabler** and has no molecular function of its own.

Picking the ChEBI term is harder than it looks. The single rule that matters most:
* **The term with the most biologist-friendly label may not be the correct one. Pick the right chemical
species deliberately. The ChEBI term should describe the ionization state at pH-7.3 (physiological pH) .**
* Note also that some chemicals, for example xenobiotics, may not have a ph-7.3 form, in which case, the non-pH-7.3 may be used.  

## Look up ChEBI via the OLS MCP

In this environment the ChEBI lookup path is the **OLS MCP**:
- `search_all_ontologies` with `ontologies: "chebi"` — search by name/synonym
- `get_terms_from_ontology` with `ontology_id: "chebi"`, `obo_id: "CHEBI:..."` — inspect a
  specific ID (definition, synonyms, obsolescence)

There is no `runoak`/OAK installed here; if you have the ontology-editing toolchain
elsewhere, an OAK recipe is in the appendix.

## The label trap (worked example)

Searching OLS for `L-histidine` returns, as the **top hit**:

- `CHEBI:15971` — *L-histidine* — "the L-enantiomer of the amino acid histidine" (neutral)

That is usually **not** the term to use. The correct term for GO-CAM is the major species
at physiological pH:

- `CHEBI:57595` — *L-histidine zwitterion* — anionic carboxy group, protonated α-amino group

The trap: `CHEBI:57595` even carries **"L-histidine" as a synonym**, so a naive name match
lands on the neutral form. Always open the definition and confirm the species.

## Two selection axes

1. **Protonation state — map to the standard form at physiological pH (~7.3).**
   Use the major protonation species at pH-7.3 (zwitterions, conjugate bases such as
   `...ate`, protonated amines), not the neutral/undissociated acid or base. e.g. use the
   *zwitterion* / *(1−)* / *(2−)* species that dominates at pH-7.3.

2. **Stereochemistry — pick the biologically correct isomer.**
   Use the specific L or D (or R/S) form. Reach for a stereo-agnostic parent only in the
   rare case where the biology genuinely is agnostic. "histidine" means L-histidine unless
   there's a reason it doesn't.

## Confirm the term is in the GO/UniProt set (UniProt-synonym check)

GO uses the subset of ChEBI that **UniProt** uses. In ChEBI those terms are marked by a
synonym whose source is **UniProt** (xref `id` `uniprot_ft`, the UniProt controlled
vocabulary). A UniProt synonym is the strongest signal that you picked the form GO expects,
and it coincides with the pH-7.3 major species: `CHEBI:57595` (L-histidine zwitterion)
carries the synonym *L-histidine* sourced from `uniprot_ft`, while the neutral
`CHEBI:15971` does **not**.

**Always check the term you chose for a UniProt synonym. If it is absent, report that to the
curator** — the term is probably not the GO/UniProt-blessed form, and there is usually a
sibling species (often the pH-7.3 form) that does carry one. This is a flag for curator
judgement, not an automatic rejection. The curator should check with ontology editors to add the ChEBI to the 'chebi-allowed' list.

The OLS **MCP** returns synonyms as a flat list **without** their source, so it cannot
answer this on its own. Use the OLS **REST API** and inspect `obo_synonym[].xrefs[].id`:

```bash
ID=57595   # the numeric part of your ChEBI ID
curl -s "https://www.ebi.ac.uk/ols4/api/ontologies/chebi/terms?iri=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FCHEBI_${ID}" \
| python3 -c 'import sys,json
t=json.load(sys.stdin)["_embedded"]["terms"][0]
hits=[s["name"] for s in (t.get("obo_synonym") or []) for x in (s.get("xrefs") or []) if "uniprot" in (x.get("id") or "").lower()]
print("UniProt synonym:", hits or "NONE — flag to curator")'
```

## GO-CAM-specific rule: one compound → one ChEBI ID across a handoff

When activity A's `has output` is the substrate (`has input`) of activity B, the causal
`provides input for` relation is **inferred from the shared molecule** (and, per
`Relation_selection.md`, not materialized for small-molecule handoffs). That inference
only fires if both sides carry the **same ChEBI ID**.

So map to the standard form *consistently*: if you use the pH-7.3 form as an output, use the **same
pH-7.3 form** as the downstream input. Mixing `CHEBI:15971` (neutral) on one activity and
`CHEBI:57595` (zwitterion) on the next describes them as two different chemicals and
**silently breaks the chain** — this is a listed common mistake in `SKILL.md`.

The same care applies to the distinct-individuals rule: a molecule playing two roles
(output of one activity, input of the next) still needs a **distinct individual per role**,
but each of those individuals must reference the **same ChEBI class**.

## Quick checklist

- [ ] Searched OLS and read the **definition**, not just the label?
- [ ] Chosen the **pH-7.3 major species** (not the neutral/undissociated form)?
- [ ] Chosen the correct **stereoisomer** (L/D, R/S)?
- [ ] Confirmed the term carries a **UniProt synonym** (`uniprot_ft` source)? If not, flag
      it to the curator — it may be outside the GO/UniProt set.
- [ ] Used the **same ChEBI ID** for the same compound everywhere it appears in the model?
- [ ] Confirmed the molecule is a genuine **primary input/output or regulator** (don't
      capture incidental chemicals — see `SKILL.md` common mistakes)?

## Appendix — pH-7.3 mapping with the ontology toolchain (optional)

If you have OAK and the Rhea mapping (not installed in this environment), the ontology
team's recipe for mapping to the standard form is:

```bash
# resolve a label to an ID
runoak -i sqlite:obo:chebi info L-histidine        # -> CHEBI:15971
# map to the pH-7.3 major species via the Rhea table
grep '^15971\t' chebi_pH7_3_mapping.tsv            # -> 15971  57595  computation
runoak -i sqlite:obo:chebi info CHEBI:57595         # -> CHEBI:57595 ! L-histidine zwitterion
```

The Rhea table (`chebi_pH7_3_mapping.tsv`) is published at
`ftp://ftp.expasy.org/databases/rhea/tsv/chebi_pH7_3_mapping.tsv`. In GO-CAM curation the
OLS route above is sufficient; this is here only for curators who also edit the ontology.
