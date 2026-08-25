---
name: amigo
description: Use whenever you need to access existing standard annotations OR bioentities (genes, gene products) in the ID space used by Noctua
---

# About

Use for finding gene products and annotations

## Command Line Client

This uses the `noctua` command line tool, which should have been installed when we ran `uv tool install noctua`

I recommend:

```
alias amigo='noctua amigo'
```

When these docs say `amigo` this can be expanded to `noctua amigo` if the alias is not set.

You can get help at any time

```
amigo --help
```

subcommands also have help


## Bioentities

Note that in AmiGO and in the GO-CAM store, MOD IDs are used for MODs, ComplexPortal for complexes, with UniProtKB (or RNA Central) IDs used for gene products in human and other species

Search bioentities

```
amigo search-bioentities --help
```

By text (eg gene symbol)

```
amigo search-bioentities -t P53
```

yields:

```
BIOENTITY       LABEL   NAME    TAXON   TYPE    SOURCE
FB:FBgn0039044  p53     p53     Drosophila melanogaster protein FB
ComplexPortal:CPX-663   p53-mdmx_human  p53-MDM4 transcriptional regulation complex     Homo sapiens    protein_complex ComplexPortal
ComplexPortal:CPX-759   p53-mdm2_human  p53-MDM2 transcriptional regulation complex     Homo sapiens    protein_complex ComplexPortal
ComplexPortal:CPX-6093  p53-mdm2_human-1        p53-MDM2-MDM4 transcriptional regulation complex        Homo sapiens    protein_complex ComplexPortal
UniProtKB:A0A9L0SIC9    TP53    Cellular tumor antigen p53      Equus caballus  protein UniProtKB
```


Restricting by taxon:

```
amigo search-bioentities -t P53 --taxon NCBITaxon:9606
```

Viewing more entities

```
amigo search-bioentities -t P53 -l 300
```

Fetching info on an entity or checking it exists:

```
amigo get-bioentity UniProtKB:P04637
```

## Annotations

All annotations for an entity:

```
amigo bioentity-annotations UniProtKB:P04637
Found 100 annotations for UniProtKB:P04637:
GO_TERM GO_NAME ASPECT  EVIDENCE        REFERENCE       WITH    QUALIFIER       ASSIGNED_BY     DATE
GO:0008285      negative regulation of cell population proliferation    P       ISS     ['PMID:30514107']       -       -       ARUK-UCL        20210810
GO:0051726      regulation of cell cycle        P       ISS     ['PMID:30514107']       -       -       ARUK-UCL        20210810
GO:1902749      regulation of cell cycle G2/M phase transition  P       IMP     ['PMID:10962037']       -       -       UniProt 20210802
GO:0006974      DNA damage response     P       IDA     ['PMID:14744935']       -       -       MGI     20101109
GO:0006983      ER overload response    P       IDA     ['PMID:14744935']       -       -       MGI     20101109
```

Note that this is truncated. Use `-l 9999` to fetch all

Search for GO annotations with filtering:

`amigo search-annotations [OPTIONS]` 
                                                                                                                                                                                      
╭─ Options ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ --bioentity    -b      TEXT     Bioentity ID to filter by                                                                                                                          │
│ --go-term      -g      TEXT     GO term ID to filter by                                                                                                                            │
│ --closure      -c      TEXT     GO terms including closure (can repeat)                                                                                                            │
│ --evidence     -e      TEXT     Evidence types to filter by (can repeat)                                                                                                           │
│ --taxon                TEXT     Organism filter                                                                                                                                    │
│ --aspect       -a      TEXT     GO aspect (C, F, or P)                                                                                                                             │
│ --assigned-by          TEXT     Annotation source filter                                                                                                                           │
│ --limit        -l      INTEGER  Maximum number of results [default: 10]                                                                                                            │
│ --base-url             TEXT     Custom GOlr endpoint URL                                                                                                                           │
│ --help                          Show this message and exit.                                                                                                                        │
╰────────────────────────────────────────────────────────────────────────────────────
