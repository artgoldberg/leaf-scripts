-- Map ICD-10-CM to SNOMED

-- Result is a set of CONCEPT_ID pairs, ICD-10-CM concept id and SNOMED concept id, plus
-- their CONCEPT_NAMEs to help review.
-- Approach: get records in CONCEPT_RELATIONSHIP that map from ICD-10-CM to SNOMED.

USE leaf_setup;

SELECT c1.CONCEPT_ID, c2.CONCEPT_ID, c1.CONCEPT_NAME, c2.CONCEPT_NAME
FROM athena.CONCEPT_RELATIONSHIP cr
    , athena.CONCEPT c1
    , athena.CONCEPT c2    
WHERE 
    c1.VOCABULARY_ID = 'ICD10CM' AND
    c2.VOCABULARY_ID = 'SNOMED' AND
    cr.RELATIONSHIP_ID = 'Maps to' AND
    c1.CONCEPT_ID = cr.CONCEPT_ID_1 AND
    c2.CONCEPT_ID = cr.CONCEPT_ID_2;

SELECT COUNT(*)
FROM athena.CONCEPT_RELATIONSHIP cr
    , athena.CONCEPT c1
    , athena.CONCEPT c2    
WHERE 
    c1.VOCABULARY_ID = 'ICD10CM' AND
    c2.VOCABULARY_ID = 'SNOMED' AND
    cr.RELATIONSHIP_ID = 'Maps to' AND
    c1.CONCEPT_ID = cr.CONCEPT_ID_1 AND
    c2.CONCEPT_ID = cr.CONCEPT_ID_2;

