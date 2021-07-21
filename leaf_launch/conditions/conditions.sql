-- Create mappings from 'Epic diagnosis IDs' to SNOMED
-- Result is a concept_map_for_loading table

-- Steps
-- 1. map 'Epic diagnosis ID' to ICD-10-CM, from the Epic concept tables in src
-- 2. map ICD-10-CM to SNOMED, using Athena's reference data
-- 3. map 'Epic diagnosis ID' to SNOMED by combining #1 and #2
-- 4. obtain existing Sharon's manual mappings of 'Epic diagnosis ID' to SNOMED, also from concept_relationship
-- 5. final 'Epic diagnosis ID' to SNOMED mapping = #4 plus mappings in #3 that are not in #4
-- 6. create concept_map_for_loading table by augmenting #5 with dependant attributes of each concept,
-- and metadata

USE omop;

-- #1
SELECT c_source.CONCEPT_ID as EPIC_DIAG_ID
    , c_dest.CONCEPT_ID as ICD10CM_CONCEPT_ID
FROM cdm_std.CONCEPT_RELATIONSHIP cr
    , cdm_std.CONCEPT c_source
    , cdm_std.CONCEPT c_dest
WHERE
    c_source.VOCABULARY_ID = 'EPIC EDG .1' AND
    cr.RELATIONSHIP_ID = 'Maps to' AND
    c_dest.VOCABULARY_ID = 'ICD10CM' AND
    c_source.CONCEPT_ID = cr.CONCEPT_ID_1 AND
    c_dest.CONCEPT_ID = cr.CONCEPT_ID_2;

-- #2
SELECT c_source.CONCEPT_ID as ICD10CM_CONCEPT_ID
    , c_dest.CONCEPT_ID as SNOMED_CONCEPT_ID
FROM cdm_std.CONCEPT_RELATIONSHIP cr
    , cdm_std.CONCEPT c_source
    , cdm_std.CONCEPT c_dest
WHERE
    c_source.VOCABULARY_ID = 'ICD10CM' AND
    cr.RELATIONSHIP_ID = 'Maps to' AND
    c_dest.VOCABULARY_ID = 'SNOMED' AND
    c_source.CONCEPT_ID = cr.CONCEPT_ID_1 AND
    c_dest.CONCEPT_ID = cr.CONCEPT_ID_2;

-- #3
SELECT epic_to_icd10.EPIC_DIAG_ID
    , icd_to_snomed.SNOMED_CONCEPT_ID

-- #1
FROM
    (SELECT c_source.CONCEPT_ID as EPIC_DIAG_ID
         , c_dest.CONCEPT_ID as ICD10CM_CONCEPT_ID
     FROM cdm_std.CONCEPT_RELATIONSHIP cr
         , cdm_std.CONCEPT c_source
         , cdm_std.CONCEPT c_dest
     WHERE
         c_source.VOCABULARY_ID = 'EPIC EDG .1' AND
         cr.RELATIONSHIP_ID = 'Maps to' AND
         c_dest.VOCABULARY_ID = 'ICD10CM' AND
         c_source.CONCEPT_ID = cr.CONCEPT_ID_1 AND
         c_dest.CONCEPT_ID = cr.CONCEPT_ID_2) epic_to_icd10,

-- #2
    (SELECT c_source.CONCEPT_ID as ICD10CM_CONCEPT_ID
         , c_dest.CONCEPT_ID as SNOMED_CONCEPT_ID
     FROM cdm_std.CONCEPT_RELATIONSHIP cr
         , cdm_std.CONCEPT c_source
         , cdm_std.CONCEPT c_dest
     WHERE
         c_source.VOCABULARY_ID = 'ICD10CM' AND
         cr.RELATIONSHIP_ID = 'Maps to' AND
         c_dest.VOCABULARY_ID = 'SNOMED' AND
         c_source.CONCEPT_ID = cr.CONCEPT_ID_1 AND
         c_dest.CONCEPT_ID = cr.CONCEPT_ID_2) icd_to_snomed

WHERE epic_to_icd10.ICD10CM_CONCEPT_ID = icd_to_snomed.ICD10CM_CONCEPT_ID





