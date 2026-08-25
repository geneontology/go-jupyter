# Evidence and evidence codes

## Evidence Codes (match what the paper shows)

Pick the evidence code for what was actually demonstrated, not for convenience:
- **IDA (ECO:0000314):** directly demonstrated (assay, imaging, direct binding/catalysis).
- **IMP (ECO:0000315):** shown via a mutant / knockdown / knockout phenotype.
- **IC (ECO:0000305):** curator inference — legitimate, but use deliberately.
- **ISS ortholog-transfer recipe** (e.g. building a human model from mouse experiments):
use the target species' identifiers (human -> UniProtKB) and taxon; put every fact on
- **ISS = ECO:0000250**, reference **GO_REF:0000024** (manual transfer by curator sequence
similarity), with `with/from` = the source ortholog's **MOD** accession (e.g. S. pombe: `Pombase:...`).
  - For a causal edge between two proteins, `with/from` may list both source orthologs.
  - ISS annotations can only be transferred from a sequence that has experimental evidence, not from a sequence that only has sequence similarity, phylogenetic or IEA evidence. 
- **IBA** annotations can be used, but these need to be fetched from AmiGO; they cannot be created
- **IEA** annotations: annotations from InterPro2GO, and other sources, may be used, but these must be fetched from AmiGO. IEA annotations should only be used when no other data can be found.
- **Important note: be honest about the presence and quality of the evidence. If a statement lacks support, warn the user, so they can help find evidence.**
