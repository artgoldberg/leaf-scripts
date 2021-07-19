-- Map ICD-10-CM to SNOMED

-- Result is a set of CONCEPT_ID pairs, mapping a ICD-10-CM concept id to a SNOMED concept id,
-- and including their CONCEPT_NAMEs to help review.
-- Approach: get records in CONCEPT_RELATIONSHIP that map from ICD-10-CM to SNOMED.

USE omop;

SELECT c1.CONCEPT_ID as ICD10CM_CONCEPT_ID
    , c2.CONCEPT_ID as SNOMED_CONCEPT_NAME
    , c1.CONCEPT_NAME as ICD10CM_CONCEPT_NAME
    , c2.CONCEPT_NAME as SNOMED_CONCEPT_NAME
FROM cdm_std.CONCEPT_RELATIONSHIP cr
    , cdm_std.CONCEPT c1
    , cdm_std.CONCEPT c2
WHERE
    c1.VOCABULARY_ID = 'ICD10CM' AND
    c2.VOCABULARY_ID = 'SNOMED' AND
    cr.RELATIONSHIP_ID = 'Maps to' AND
    c1.CONCEPT_ID = cr.CONCEPT_ID_1 AND
    c2.CONCEPT_ID = cr.CONCEPT_ID_2;

SELECT COUNT(*)
FROM cdm_std.CONCEPT_RELATIONSHIP cr
    , cdm_std.CONCEPT c1
    , cdm_std.CONCEPT c2
WHERE
    c1.VOCABULARY_ID = 'ICD10CM' AND
    c2.VOCABULARY_ID = 'SNOMED' AND
    cr.RELATIONSHIP_ID = 'Maps to' AND
    c1.CONCEPT_ID = cr.CONCEPT_ID_1 AND
    c2.CONCEPT_ID = cr.CONCEPT_ID_2;
