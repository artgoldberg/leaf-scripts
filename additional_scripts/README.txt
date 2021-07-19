Comments from Nicholas J. Dobbins <ndobb@uw.edu>:

This folder contains ... scripts ... recently shared with UCSD for creating a Medication hierarchy from Epic Clarity, as well as a means of creating an ICD-10 diagnosis tree ... .

Regarding diagnosis & procedures, long-term, ideally we’ll of course use the native OMOP CDM tables, but as a short-term expedient the script here for ICD-10 uses a pre-generated parent-child table from UMLS (the icd10.sql file) with WHERE clauses that can use the OMOP [condition_source_value] column, assuming it is coded in ICD-10 (like our discussion here https://github.com/uwrit/leaf/discussions/398).  
 
I don’t have a similar script ready for procedures but can generate one easily enough when I return. What procedure coding systems are you planning to use? (CPT, ICD10 & 9?) Please also note the (short) leaf_icd10.sql script is fairly quick-and-dirty; I adapted it from my original work at UW but haven’t had a chance to test it so please review and adjust as needed before running.
 
Clarity_medication.sql – adds a Medication tree. Before running, in the Leaf Admin UI you should make a root “Medications” concept, and add a Concept SqlSet for the table/view you want to query (probably Clarity ORDER_MED).

Icd10.sql – this creates a table called dbo.UMLS_ICD10 which contains the ICD10 tree & parent-child relations, as well as SQL WHERE clauses. (You can DROP this table after Leaf config is done)

Leaf_icd10.sql – this script uses the dbo.UMLS_ICD10 table to insert diagnosis concepts in the Leaf app.Concept table and configure the hierarchy. Before running, in the Leaf Admin UI you should make a root “Diagnoses” concept, and add a Concept SqlSet for the table/view you want to query.
