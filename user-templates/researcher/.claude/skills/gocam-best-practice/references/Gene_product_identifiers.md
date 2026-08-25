# Gene product identifiers: MOD accessions vs UniProtKB

Enablers are gene product (protein or RNA) or protein-containing complex that mediates the Molecular Function. The correct identifier must be selected, which depends on the organism annotated. It is essential that the identifiers match the following guidelines (this is not something that a curator should be able to specify):

Identify gene products by the **model-organism-database (MOD) accession** for the species:
* Mouse: **MGI**
* Rat: **RGD**
* Zebrafish: **ZFIN**
* Fly: **FB**
* Budding yeast: **SGD**
* Worm: **WB**
* Schizosaccharomyces pombe: **PomBase**
* Other organisms with MOD-ID identifiers: Arabidopsis thaliana, Candida albicans, Dictyostelium discoideum, Escherichia coli K12 (but not other E. coli strains), Schizosaccharomyces japonicus, Xenopus laevis and Xenopus tropicalis.
* **For Human and all other organisms** -> use UniProtKB** (human has no MOD gene-product id in GO). This also applies to the `with/from` field of ISS evidence or any inputs: use the source ortholog's **MOD** id (e.g. mouse `MGI:MGI:1330299`), not its UniProtKB accession.
* If the namespace is not clear, refer to `mod_id_space` field of https://github.com/geneontology/go-site/blob/master/metadata/goex.yaml
* **MGI namespace exception**: Note that for MGI, the ID also contains the namespace, so that the full ID has the namespace repeated twice: the ID are formed as `MGI:MGI:133029`, not `MGI:133029`.
