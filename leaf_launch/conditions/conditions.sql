/*
 * Create mappings from 'Epic diagnosis IDs' to SNOMED
 * Result is a concept_map_for_loading table
 * Author: Arthur.Goldberg@mssm.edu
 */

-- Steps
-- 0. Create diagnosis_map table
-- 1. Map 'Epic diagnosis ID' to ICD-10-CM, from the Epic concept tables in src
-- 2. Incorporate mappings from ICD-10-CM to SNOMED, from Athena's reference data
-- 3. Integrate Sharon's existing manual mappings of 'Epic diagnosis ID' to SNOMED, from concept_relationship
-- 3a. If manual mapping is consistent, mark diagnosis_map.HAND_MAP_STATUS 'CONSISTENT'
-- 3b. If manual mapping conflicts, mark diagnosis_map.HAND_MAP_STATUS 'CONFLICTED',
--     replace ICD-10-CM and SNOMED values, and update SOURCES
-- 3c. If manual mapping is missing, mark diagnosis_map.HAND_MAP_STATUS 'MISSING',
--     add 'Epic diagnosis ID' ICD-10-CM and SNOMED values, and update SOURCES
-- 4. Create concept_map_for_loading table by augmenting #5 with dependant attributes of each concept, and metadata


USE rpt;

-- 0. Create diagnosis_map table
-- Schema for table mapping diagnosis concept ids
-- Must be executed as goldba06@msnyuhealth.org

USE rpt;

IF (NOT EXISTS (SELECT *
                 FROM INFORMATION_SCHEMA.TABLES
                 WHERE TABLE_SCHEMA = 'LEAF_SCRATCH'
                 AND  TABLE_NAME = 'diagnosis_map'))
BEGIN
    CREATE TABLE LEAF_SCRATCH.diagnosis_map
    (
        EPIC_CONCEPT_CODE NVARCHAR(50) NOT NULL PRIMARY KEY,
        EPIC_CONCEPT_NAME NVARCHAR(200) NOT NULL,
        ICD10_CONCEPT_CODE NVARCHAR(50),
        ICD10_CONCEPT_NAME NVARCHAR(200),
        SNOMED_CONCEPT_CODE NVARCHAR(50),
        SNOMED_CONCEPT_NAME NVARCHAR(200),
        -- Relationship of Sharon's hand-coded Epic -> SNOMED mapping to automated mapping
        HAND_MAP_STATUS NVARCHAR(50),
        SOURCES NVARCHAR(200) NOT NULL,     -- Sources for a record
        COMMENT NVARCHAR(200)
    )
END


-- 1. Map 'Epic diagnosis ID' to ICD-10-CM, from the Epic concept tables in src
-- Filter to Epic codes that map 1-to-1 to ICD10 and have been used in clinical events.

USE src;

-- get count of mapped ICD10 codes for each Epic id
WITH epic_id_map_freq AS
    (SELECT DiagnosisDim.DiagnosisEpicId, COUNT(DTD.Value) num_ICD10_codes
    FROM src.caboodle.DiagnosisDim DiagnosisDim
         INNER JOIN caboodle.DiagnosisTerminologyDim DTD ON DiagnosisDim.DiagnosisKey = DTD.DiagnosisKey
    WHERE DTD.[Type] = 'ICD-10-CM'
    GROUP BY DiagnosisDim.DiagnosisEpicId)

-- insert Epic diagnosis codes that map 1-to-1 to ICD10
INSERT INTO rpt.LEAF_SCRATCH.diagnosis_map (EPIC_CONCEPT_CODE, EPIC_CONCEPT_NAME, ICD10_CONCEPT_CODE,
    ICD10_CONCEPT_NAME, SOURCES)
SELECT DiagnosisDim.DiagnosisEpicId, DiagnosisDim.name, DTD.Value, DTD.DisplayString, 'Caboodle'
FROM src.caboodle.DiagnosisDim DiagnosisDim
    INNER JOIN caboodle.DiagnosisTerminologyDim DTD ON DiagnosisDim.DiagnosisKey = DTD.DiagnosisKey
WHERE DTD.[Type] = 'ICD-10-CM'
    AND DiagnosisDim.DiagnosisEpicId IN (SELECT DiagnosisEpicId
                                         FROM epic_id_map_freq
                                         WHERE epic_id_map_freq.num_ICD10_codes = 1)
    -- get active diagnoses
    AND DiagnosisDim.DiagnosisEpicId IN (SELECT DISTINCT DiagnosisKey
                                         FROM src.caboodle.DiagnosisEventFact)


-- 2. Incorporate mappings from ICD-10-CM to SNOMED, from Athena's reference data
USE omop;

UPDATE rpt.LEAF_SCRATCH.diagnosis_map
SET SNOMED_CONCEPT_CODE = concept_SNOMED.CONCEPT_ID
    ,SNOMED_CONCEPT_NAME = concept_SNOMED.CONCEPT_NAME
FROM cdm_std.CONCEPT_RELATIONSHIP cr
    ,cdm_std.CONCEPT concept_ICD10
    ,cdm_std.CONCEPT concept_SNOMED
WHERE
    -- get records in CONCEPT_RELATIONSHIP that map from ICD-10-CM to SNOMED
    concept_ICD10.VOCABULARY_ID = 'ICD10CM'
    AND concept_SNOMED.VOCABULARY_ID = 'SNOMED'
    AND cr.RELATIONSHIP_ID = 'Maps to'
    AND concept_ICD10.CONCEPT_ID = cr.CONCEPT_ID_1
    AND concept_SNOMED.CONCEPT_ID = cr.CONCEPT_ID_2
    -- join with ICD-10-CM records in LEAF_SCRATCH.diagnosis_map
    AND rpt.LEAF_SCRATCH.diagnosis_map.ICD10_CONCEPT_CODE = concept_ICD10.concept_code


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