# Note
This is a copy of the official documentation, found at: https://docs.google.com/document/d/1a5YZBJrnJ9LKJxPVpXk62dJJGpHB2b9zH8-xr_Rm1Vs/edit?tab=t.detiv7ampq5e#heading=h.k867b2synj85

# Aim of GO-CAMs
GO-CAMs (Gene Ontology Causal Activity Models) are designed to represent:
'activity units' (the basic annotation unit in GO-CAM that combines MF, BP, and CC for a single gene product) that specify how different GO annotations relate to each other.
‘pathways’ that specify the flow of causal connections between the activities of different gene products, to accomplish or regulate a larger biological process.

Formally, GO-CAMs are constructed by joining together standard GO annotations (one gene product and one GO term) into a larger model of a biological process or pathway. 
Hence, standard annotations can be used to help build a GO-CAM model. 
GO-CAM models depict a biological pathway or process in which multiple activities can be interconnected into a causal flow. However, in cases where activities cannot 
be connected, either because they have no causal relations, or the causal relations are unknown, then one or more standard GO annotation(s) will suffice to describe the data. 
Note that some papers may contain data that is appropriate for GO-CAM, and other results appropriate for standard annotations. 

# Capturing Molecular Functions in GO-CAM
In GO-CAM, the molecular function term employed should accurately describe the protein's activity during the specific process depicted in the model.

Whenever possible, there should be one activity unit per gene product, and the detailed mechanism description should be in the definition of the MF term. 
There is an exception to this rule for multifunctional proteins in which distinct catalytic activities are carried out by distinct domains of a protein, 
e.g. subsequent steps in a biochemical pathway, or histone reader and writer activity. In these cases, create distinct activity units for each catalytic domain 
and link them with causal relations. Note that this exception applies only when the domains have genuinely independent catalytic activities, not when they work together 
to perform a single molecular function.

# What NOT to include in GO-CAM models 
- Molecular Function binding terms (GO:0005515 and children) are not normally annotated in GO-CAM, as they do not adequately describe the protein's activity.
- Non-catalytic MF can be harder to identify, see documentation on non-catalytic MF for suggestions to replace 'binding' terms. 
- Reversible reactions: As GO-CAM captures an activity flow, even if a MF is potentially reversible, in a GO-CAM, only a single direction should be relevant.
- Mechanistic description of the function belongs in the definition of the MF term rather than in the GO-CAM model. For example, a tyrosine protein kinase receptor’s activity could in principle be broken down into separate steps like ligand binding, followed by autophosphorylation, followed by recruitment of signaling complex components (binding). Instead, curators should use a single activity unit with an MF term (in this case, GO:0004714, transmembrane receptor tyrosine protein kinase activity) which includes all of these mechanistic steps.


