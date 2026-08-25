# PubMed searches via NCBI E-utilities

Use NCBI E-utilities directly via curl. Do NOT use a PubMed MCP.
Always include `email=help@geneontology.org&tool=go-jupyter&api_key=$NCBI_API_KEY` in requests.
The `NCBI_API_KEY` env var is pre-set in your environment.
Always report PMIDs instead of or in addition to DOIs.

Two-step workflow:

1. **Search for PMIDs** (esearch):
   ```
   curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmax=50&term=QUERY&retmode=json&email=help@geneontology.org&tool=go-jupyter&api_key=$NCBI_API_KEY"
   ```
   Returns JSON with a list of PMIDs in `esearchresult.idlist`.

2. **Fetch details** (esummary for metadata, efetch for full abstracts):
   ```
   curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id=PMID1,PMID2,...&retmode=json&email=help@geneontology.org&tool=go-jupyter&api_key=$NCBI_API_KEY"
   ```
   Returns title, authors, journal, date, DOI per article.

   For full abstracts use efetch with XML:
   ```
   curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=PMID1,PMID2,...&retmode=xml&email=help@geneontology.org&tool=go-jupyter&api_key=$NCBI_API_KEY"
   ```
