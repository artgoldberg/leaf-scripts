-- Create mappings from 'Epic diagnosis IDs' to SNOMED
-- Result is a concept_map_for_loading table

-- Steps
-- 0. Create diagnosis_map table
-- 1. Map 'Epic diagnosis ID' to ICD-10-CM, from the Epic concept tables in src
-- 2. Integrate map of ICD-10-CM to SNOMED, from Athena's reference data
-- 3. Integrate Sharon's existing manual mappings of 'Epic diagnosis ID' to SNOMED, from concept_relationship
-- 3a. If manual mapping is consistent, mark diagnosis_map.HAND_MAP_STATUS 'CONSISTENT'
-- 3b. If manual mapping conflicts, mark diagnosis_map.HAND_MAP_STATUS 'CONFLICTED',
--     replace ICD-10-CM and SNOMED values, and update SOURCES
-- 3c. If manual mapping is missing, mark diagnosis_map.HAND_MAP_STATUS 'MISSING',
--     add 'Epic diagnosis ID' ICD-10-CM and SNOMED values, and update SOURCES
-- 4. Create concept_map_for_loading table by augmenting #5 with dependant attributes of each concept, and metadata


USE rpt;


-- #3
WITH epic_n_athenas_mappings AS
    (SELECT epic_to_icd10.EPIC_DIAG_ID
    , icd_to_snomed.SNOMED_CONCEPT_ID

    -- #1
    FROM
        (SELECT c_source.CONCEPT_ID as EPIC_DIAG_ID
             , c_dest.CONCEPT_ID as ICD10CM_CONCEPT_ID
         FROM xxx
         WHERE yyy) epic_to_icd10,

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

    WHERE epic_to_icd10.ICD10CM_CONCEPT_ID = icd_to_snomed.ICD10CM_CONCEPT_ID)


-- #4
WITH sharons_mappings AS
    (SELECT c_source.CONCEPT_ID as EPIC_DIAG_ID
         , c_dest.CONCEPT_ID as SNOMED_CONCEPT_ID
     FROM cdm_std.CONCEPT_RELATIONSHIP cr
         , cdm_std.CONCEPT c_source
         , cdm_std.CONCEPT c_dest
     WHERE
         c_source.VOCABULARY_ID = 'EPIC EDG .1' AND
         cr.RELATIONSHIP_ID = 'Maps to' AND
         c_dest.VOCABULARY_ID = 'SNOMED' AND
         c_source.CONCEPT_ID = cr.CONCEPT_ID_1 AND
         c_dest.CONCEPT_ID = cr.CONCEPT_ID_2)

WITH combined_mappings AS
    (SELECT
    sharons_mappings
    epic_n_athenas_mappings
    UNION
        SELECT * FROM sharons_mappings

    )