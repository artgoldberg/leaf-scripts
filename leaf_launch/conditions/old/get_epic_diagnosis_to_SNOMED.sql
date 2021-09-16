-- Get 'Epic diagnosis ID' → SNOMED mappings by Sharon from concept_relationship

-- Result is a set of CONCEPT_ID pairs, mapping an 'Epic diagnosis ID' to a SNOMED concept id, along with their CONCEPT_NAMEs to help review.


-- Approach: get records in CONCEPT_RELATIONSHIP that map from 'EPIC EDG .1' to 'SNOMED'

USE omop;

SELECT c_source.CONCEPT_ID as EPIC_DIAG_ID
    , c_source.CONCEPT_NAME as EPIC_DIAG_NAME
    , c_dest.CONCEPT_ID as SNOMED_CONCEPT_ID
    , c_dest.CONCEPT_NAME as SNOMED_CONCEPT_NAME
FROM cdm_phi_std.CONCEPT_RELATIONSHIP cr
    , cdm_phi_std.CONCEPT c_source
    , cdm_phi_std.CONCEPT c_dest
WHERE
    c_source.VOCABULARY_ID = 'EPIC EDG .1' AND
    cr.RELATIONSHIP_ID = 'Maps to' AND
    c_dest.VOCABULARY_ID = 'SNOMED' AND
    c_source.CONCEPT_ID = cr.CONCEPT_ID_1 AND
    c_dest.CONCEPT_ID = cr.CONCEPT_ID_2;


SELECT COUNT(*)
FROM cdm_phi_std.CONCEPT_RELATIONSHIP cr
    , cdm_phi_std.CONCEPT c_source
    , cdm_phi_std.CONCEPT c_dest
WHERE
    c_source.VOCABULARY_ID = 'EPIC EDG .1' AND
    cr.RELATIONSHIP_ID = 'Maps to' AND
    c_dest.VOCABULARY_ID = 'SNOMED' AND
    c_source.CONCEPT_ID = cr.CONCEPT_ID_1 AND
    c_dest.CONCEPT_ID = cr.CONCEPT_ID_2;
