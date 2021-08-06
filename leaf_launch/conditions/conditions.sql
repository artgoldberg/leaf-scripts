/*
 * Create mappings from 'Epic diagnosis IDs' to SNOMED
 * Result is a concept_map_for_loading table
 * Author: Arthur.Goldberg@mssm.edu
 */

/*
Must be executed as goldba06@MSNYUHEALTH.ORG.

Steps
0. Create diagnosis_map table
1. Map 'Epic diagnosis ID' to ICD-10-CM, from the Epic concept tables in src
2. Incorporate mappings from ICD-10-CM to SNOMED, from Athena's reference data
3. Integrate Sharon's existing manual mappings of 'Epic diagnosis ID' to SNOMED, from concept_relationship
3a. If manual mapping is consistent, mark diagnosis_map.hand_map_status 'CONSISTENT'
3b. If manual mapping conflicts, mark diagnosis_map.hand_map_status 'CONFLICTED',
    use the manual value selected for SNOMED, and the ICD-10-CM value that implies, and update sources
3c. If manual mapping is missing, mark diagnosis_map.hand_map_status 'MISSING',
    add 'Epic diagnosis ID' ICD-10-CM and SNOMED values, and update sources
4. Validate the diagnosis_map
5. Create concept_map_for_loading table by augmenting the diagnosis_map
*/

/*
Formatting todos:
    change 'manual mappings' to 'curated mappings'
    clean up comments
*/


-- 0. Create diagnosis_map table
-- Schema for table mapping diagnosis concept ids

PRINT 'Starting ''conditions.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120)

USE rpt;

IF (NOT EXISTS (SELECT *
                FROM information_schema.tables
                WHERE table_schema = 'leaf_scratch'
                AND table_name = 'diagnosis_map'))
    BEGIN
        CREATE TABLE leaf_scratch.diagnosis_map
        (
            Epic_concept_code NVARCHAR(50) NOT NULL PRIMARY KEY,
            Epic_concept_name NVARCHAR(255) NOT NULL,
            ICD10_concept_code NVARCHAR(50),
            ICD10_concept_name NVARCHAR(255),
            SNOMED_concept_code NVARCHAR(50),
            SNOMED_concept_name NVARCHAR(255),
            -- Relationship of Sharon's hand-coded Epic -> SNOMED mapping to automated mapping
            hand_map_status NVARCHAR(50),
            sources NVARCHAR(200) NOT NULL,     -- Sources for a record
            comment NVARCHAR(200)
        )
    END
ELSE
    DELETE FROM leaf_scratch.diagnosis_map


-- 1. Map 'Epic diagnosis ID' to ICD-10-CM, from the Epic concept tables in src
-- Filter to Epic codes that map 1-to-1 to ICD10 and have been used in clinical events

USE src;

-- Obtain and report number of Epic id that maps 1-to-many to ICD10 codes in Caboodle
DECLARE @cardinality_epic_to_icd10 TABLE (Epic_concept_code NVARCHAR(50) PRIMARY KEY,
                                          num_ICD10_concept_codes INT)

INSERT INTO @cardinality_epic_to_icd10
    SELECT DiagnosisDim.DiagnosisEpicId, COUNT(DTD.Value)
    FROM src.caboodle.DiagnosisDim DiagnosisDim
        INNER JOIN caboodle.DiagnosisTerminologyDim DTD ON DiagnosisDim.DiagnosisKey = DTD.DiagnosisKey
    WHERE DTD.[Type] = 'ICD-10-CM'
    -- Avoid non-Clarity data added by Population Health
    AND DTD._HasSourceClarity = 1 AND DTD._IsDeleted = 0
    AND DiagnosisDim._HasSourceClarity = 1 AND DiagnosisDim._IsDeleted = 0
    -- Get active diagnoses
    AND DiagnosisDim.DiagnosisEpicId IN (SELECT DISTINCT DiagnosisKey
                                         FROM src.caboodle.DiagnosisEventFact)
    GROUP BY DiagnosisDim.DiagnosisEpicId

DECLARE @num_1_to_many_mappings INT = (SELECT COUNT(*)
                                       FROM @cardinality_epic_to_icd10
                                       WHERE 1 < [@cardinality_epic_to_icd10].num_ICD10_concept_codes)
PRINT 'Ignoring ' + CAST(@num_1_to_many_mappings AS VARCHAR) +
      ' Epic diagnosis codes that map 1-to-many to ICD10 in Epic'

-- Insert Epic diagnosis codes that map 1-to-1 to ICD10
INSERT INTO rpt.leaf_scratch.diagnosis_map (Epic_concept_code, Epic_concept_name,
            ICD10_concept_code, ICD10_concept_name, sources)
SELECT DiagnosisDim.DiagnosisEpicId, DiagnosisDim.name, DTD.Value, DTD.DisplayString, 'Caboodle'
FROM src.caboodle.DiagnosisDim DiagnosisDim
    INNER JOIN caboodle.DiagnosisTerminologyDim DTD ON DiagnosisDim.DiagnosisKey = DTD.DiagnosisKey
WHERE DTD.[Type] = 'ICD-10-CM'
    -- Avoid non-Clarity data added by Population Health
    AND DTD._HasSourceClarity = 1 AND DTD._IsDeleted = 0
    AND DiagnosisDim._HasSourceClarity = 1 AND DiagnosisDim._IsDeleted = 0
    -- Use Epic diagnosis codes that map 1-to-1 to ICD10
    AND DiagnosisDim.DiagnosisEpicId IN (SELECT Epic_concept_code
                                         FROM @cardinality_epic_to_icd10
                                         WHERE [@cardinality_epic_to_icd10].num_ICD10_concept_codes = 1)
    -- Get active diagnoses
    AND DiagnosisDim.DiagnosisEpicId IN (SELECT DISTINCT DiagnosisKey
                                         FROM src.caboodle.DiagnosisEventFact)
    -- Don't map to ICD-10-CM IMO0001, which codes for 'Reserved for inherently not codable concepts without codable children'
    -- or to IMO0002, 'Reserved for concepts with insufficient information to code with codable children'
    AND NOT DTD.Value IN('IMO0001', 'IMO0002');

-- 2. Incorporate mappings from ICD-10-CM to SNOMED, from Athena's reference data

UPDATE rpt.leaf_scratch.diagnosis_map
SET SNOMED_concept_code = concept_SNOMED.concept_code,
    SNOMED_concept_name = concept_SNOMED.concept_name
FROM omop.cdm_std.concept_relationship cr,
     omop.cdm_std.concept concept_ICD10,
     omop.cdm_std.concept concept_SNOMED
WHERE
    -- get records in CONCEPT_RELATIONSHIP that map from ICD-10-CM to SNOMED
    concept_ICD10.vocabulary_id = 'ICD10CM'
    AND concept_SNOMED.vocabulary_id = 'SNOMED'
    AND cr.relationship_id = 'Maps to'
    AND concept_ICD10.concept_id = cr.concept_id_1
    AND concept_SNOMED.concept_id = cr.concept_id_2
    -- join with ICD-10-CM records in leaf_scratch.diagnosis_map
    AND rpt.leaf_scratch.diagnosis_map.ICD10_concept_code = concept_ICD10.concept_code;


-- 3. Integrate Sharon's existing manual mappings of 'Epic diagnosis ID' to SNOMED, from concept_relationship
-- Make temp table for the manual mappings
IF OBJECT_ID(N'tempdb..#manual_mappings') IS NOT NULL
	DROP TABLE #manual_mappings
CREATE TABLE #manual_mappings(
    Epic_concept_code NVARCHAR(50) NOT NULL,
    Epic_concept_name NVARCHAR(255) NOT NULL,
    SNOMED_concept_code NVARCHAR(50) NOT NULL,
    SNOMED_concept_name NVARCHAR(255)
)

INSERT INTO #manual_mappings
SELECT concept_EPIC.concept_code,
       concept_EPIC.concept_name,
       concept_SNOMED.concept_code,
       concept_SNOMED.concept_name
FROM omop.cdm_std.CONCEPT_RELATIONSHIP cr,
     omop.cdm_std.CONCEPT concept_EPIC,
     omop.cdm_std.CONCEPT concept_SNOMED
WHERE
    concept_EPIC.vocabulary_id = 'EPIC EDG .1'
    AND cr.relationship_id = 'Maps to'
    AND concept_SNOMED.vocabulary_id = 'SNOMED'
    AND concept_EPIC.concept_id = cr.concept_id_1
    AND concept_SNOMED.concept_id = cr.concept_id_2

DECLARE @num_manual_mappings INT = (SELECT COUNT(*) FROM #manual_mappings)
PRINT CAST(@num_manual_mappings AS VARCHAR) + ' manual mappings from EPIC EDG .1 to SNOMED found in cdm_std'

-- The manual mappings of 'Epic diagnosis ID' to SNOMED contain 1-to-many mappings; record and ignore them
DECLARE @cardinality_manual_mappings TABLE (Epic_concept_code NVARCHAR(50) PRIMARY KEY,
                                            num_SNOMED_concept_codes INT)
INSERT INTO @cardinality_manual_mappings
    SELECT Epic_concept_code, COUNT(SNOMED_concept_code) num_SNOMED_concept_codes
    FROM #manual_mappings
    GROUP BY Epic_concept_code

SELECT #manual_mappings.Epic_concept_code,
       #manual_mappings.Epic_concept_name,
       #manual_mappings.SNOMED_concept_code,
       #manual_mappings.SNOMED_concept_name
    FROM @cardinality_manual_mappings,
         #manual_mappings
    WHERE [@cardinality_manual_mappings].Epic_concept_code = #manual_mappings.Epic_concept_code
          AND 1 < num_SNOMED_concept_codes
    ORDER BY #manual_mappings.Epic_concept_code

DELETE
FROM #manual_mappings
WHERE Epic_concept_code IN (SELECT Epic_concept_code
                            FROM @cardinality_manual_mappings
                            WHERE 1 < num_SNOMED_concept_codes)

DECLARE @num_manual_mappings_2 INT = (SELECT COUNT(*) FROM #manual_mappings)
PRINT CAST(@num_manual_mappings_2 AS VARCHAR) + ' 1-to-1 manual mappings from EPIC EDG .1 to SNOMED found in cdm_std'


-- 3a. If manual mapping is consistent, mark diagnosis_map.hand_map_status as 'CONSISTENT', and update sources
UPDATE rpt.leaf_scratch.diagnosis_map
SET hand_map_status = 'CONSISTENT',
    sources = 'Caboodle and MANUAL'
FROM #manual_mappings,
     rpt.leaf_scratch.diagnosis_map diagnosis_map
WHERE diagnosis_map.Epic_concept_code = #manual_mappings.Epic_concept_code
    AND diagnosis_map.SNOMED_concept_code = #manual_mappings.SNOMED_concept_code


-- 3b. If manual mapping conflicts, mark diagnosis_map.hand_map_status 'CONFLICTED',
--     use the manual value for SNOMED, the ICD-10-CM value that implies, and update sources
UPDATE rpt.leaf_scratch.diagnosis_map
SET hand_map_status = 'CONFLICTED',
    SNOMED_concept_code = #manual_mappings.SNOMED_concept_code,
    SNOMED_concept_name = #manual_mappings.SNOMED_concept_name,
    sources = 'MANUAL'
FROM #manual_mappings,
     rpt.leaf_scratch.diagnosis_map diagnosis_map
WHERE diagnosis_map.Epic_concept_code = #manual_mappings.Epic_concept_code
    AND NOT diagnosis_map.SNOMED_concept_code = #manual_mappings.SNOMED_concept_code

-- 3b continued; insert the ICD-10-CM value associated with the manually mapped value for SNOMED
UPDATE rpt.leaf_scratch.diagnosis_map
SET ICD10_concept_code = concept_ICD10.concept_code,
    ICD10_concept_name = concept_ICD10.concept_name
FROM #manual_mappings,
     rpt.leaf_scratch.diagnosis_map diagnosis_map,
     omop.cdm_std.concept_relationship cr,
     omop.cdm_std.concept concept_ICD10,
     omop.cdm_std.concept concept_SNOMED
WHERE diagnosis_map.sources = 'MANUAL'
    -- get records in CONCEPT_RELATIONSHIP that map from ICD-10-CM to SNOMED
    AND concept_ICD10.vocabulary_id = 'ICD10CM'
    AND concept_SNOMED.vocabulary_id = 'SNOMED'
    AND cr.relationship_id = 'Maps to'
    AND concept_ICD10.concept_id = cr.concept_id_1
    AND concept_SNOMED.concept_id = cr.concept_id_2
    AND diagnosis_map.SNOMED_concept_code = concept_SNOMED.concept_code


-- 3c. If manual mapping is missing, insert diagnosis_map record with hand_map_status = 'MISSING',
--     'Epic diagnosis ID', SNOMED values from manual mappings, and sources
DECLARE @num_mappings_left INT = (SELECT COUNT(*)
                                  FROM #manual_mappings
                                  WHERE #manual_mappings.Epic_concept_code
                                  NOT IN(SELECT diagnosis_map.Epic_concept_code
                                         FROM rpt.leaf_scratch.diagnosis_map diagnosis_map))
PRINT CAST(@num_mappings_left AS VARCHAR) + ' manual mappings of EPIC to SNOMED are not found in Caboodle'

INSERT INTO rpt.leaf_scratch.diagnosis_map(Epic_concept_code,
                                           Epic_concept_name,
                                           SNOMED_concept_code,
                                           SNOMED_concept_name,
                                           hand_map_status,
                                           sources)
SELECT #manual_mappings.Epic_concept_code,
       #manual_mappings.Epic_concept_name,
       #manual_mappings.SNOMED_concept_code,
       #manual_mappings.SNOMED_concept_name,
       'MISSING',
       'MANUAL MAPPINGS'
FROM #manual_mappings
WHERE #manual_mappings.Epic_concept_code NOT IN (SELECT Epic_concept_code
                                                 FROM rpt.leaf_scratch.diagnosis_map)

-- 3c continued; insert the ICD-10-CM value associated with the manually mapped value for SNOMED
UPDATE rpt.leaf_scratch.diagnosis_map
SET ICD10_concept_code = concept_ICD10.concept_code,
    ICD10_concept_name = concept_ICD10.concept_name
FROM rpt.leaf_scratch.diagnosis_map diagnosis_map,
    omop.cdm_std.concept_relationship cr,
    omop.cdm_std.concept concept_ICD10,
    omop.cdm_std.concept concept_SNOMED
WHERE diagnosis_map.hand_map_status = 'MISSING'
    -- get records in CONCEPT_RELATIONSHIP that map from ICD-10-CM to SNOMED
    AND concept_ICD10.vocabulary_id = 'ICD10CM'
    AND concept_SNOMED.vocabulary_id = 'SNOMED'
    AND cr.relationship_id = 'Maps to'
    AND concept_ICD10.concept_id = cr.concept_id_1
    AND concept_SNOMED.concept_id = cr.concept_id_2
    AND diagnosis_map.SNOMED_concept_code = concept_SNOMED.concept_code;

-- 4. Validate the diagnosis_map
-- Ensure that there are no NULLs values for ICD10 or SNOMED codes, so all EPIC codes can be fully mapped
-- Count and then remove records containing SNOMED codes that do not contain a mapping to ICD-10-CM in CONCEPT_RELATIONSHIP
DECLARE @num_icd10_nulls INT = (SELECT COUNT(*)
                                FROM rpt.leaf_scratch.diagnosis_map
                                WHERE ICD10_concept_code IS NULL)
PRINT 'Deleting ' + CAST(@num_icd10_nulls AS VARCHAR) + ' records that lack an ICD-10-CM code'

DELETE
FROM rpt.leaf_scratch.diagnosis_map
WHERE ICD10_concept_code IS NULL

-- Count and then remove records missing SNOMED codes
DECLARE @num_snomed_nulls INT = (SELECT COUNT(*)
                                 FROM rpt.leaf_scratch.diagnosis_map
                                 WHERE SNOMED_concept_code IS NULL)
PRINT 'Deleting ' + CAST(@num_snomed_nulls AS VARCHAR) + ' records that lack a SNOMED code'

DELETE
FROM rpt.leaf_scratch.diagnosis_map
WHERE SNOMED_concept_code IS NULL;

-- Ensure that all EPIC EDG .1 → SNOMED are 1-to-1, so condition_concept_id can be unambiguously initialized
DECLARE @cardinality_Epic_2_SNOMED_mappings TABLE (Epic_concept_code NVARCHAR(50) PRIMARY KEY,
                                                   num_SNOMED_concept_codes INT)
INSERT INTO @cardinality_Epic_2_SNOMED_mappings
SELECT Epic_concept_code, COUNT(SNOMED_concept_code)
    FROM rpt.leaf_scratch.diagnosis_map
    GROUP BY Epic_concept_code
IF EXISTS (SELECT *
           FROM @cardinality_Epic_2_SNOMED_mappings
           WHERE 1 < num_SNOMED_concept_codes)
BEGIN
   DECLARE @msg VARCHAR = 'Some EPIC EDG .1 to SNOMED mappings are 1-to-many, so condition_concept_id ' +
                          'cannot be unambiguously initialized'
   RAISERROR(@msg, 16, 0)
END

-- Count the unique ICD10 codes in the diagnosis_map
DECLARE @num_ICD10_codes INT = (SELECT COUNT(DISTINCT ICD10_concept_code)
                                FROM rpt.leaf_scratch.diagnosis_map)
PRINT CAST(@num_ICD10_codes AS VARCHAR) + ' unique ICD10 codes found'

-- 5. Create concept_map_for_loading table by augmenting the diagnosis_map with dependant attributes of each concept, and metadata
USE rpt;

IF (NOT EXISTS (SELECT *
                FROM information_schema.tables
                WHERE table_schema = 'leaf_scratch'
                AND table_name = 'concept_map_for_loading'))
    BEGIN
        CREATE TABLE leaf_scratch.concept_map_for_loading
        (
            source_concept_code VARCHAR(50) NOT NULL,
            source_concept_name VARCHAR(255) NOT NULL,
            source_concept_vocabulary_id VARCHAR(50) NOT NULL,
            value_as_source_concept_code BIGINT,
            value_as_source_concept_name VARCHAR(255),
            value_as_source_concept_vocabulary_id VARCHAR(50),
            target_concept_id BIGINT NOT NULL,
            target_concept_code VARCHAR(50) NOT NULL,
            target_concept_name VARCHAR(255) NOT NULL,
            target_concept_vocabulary_id VARCHAR(50) NOT NULL,
            target_value_as_concept_id BIGINT,
            target_value_as_concept_code VARCHAR(50),
            target_value_as_concept_name VARCHAR(255),
            target_value_as_concept_vocabulary_id VARCHAR(50),
            target_value_as_number BIGINT,
            target_unit_concept_id BIGINT,
            target_unit_concept_code VARCHAR(50),
            target_unit_concept_name VARCHAR(255),
            target_unit_concept_vocabulary_id VARCHAR(50),
            TARGET_QUALIFIER_CONCEPT_ID VARCHAR(50),
            TARGET_QUALIFIER_concept_code VARCHAR(50),
            TARGET_QUALIFIER_concept_name VARCHAR(255),
            TARGET_QUALIFIER_CONCEPT_VOCABULARY_ID VARCHAR(50),
            mapping_equivalence VARCHAR(50),
            mapping_creation_user VARCHAR(50) NOT NULL,
            mapping_creation_datetime datetime NOT NULL,
            mapping_status VARCHAR(50),
            mapping_status_user VARCHAR(50),
            mapping_status_datetime DATETIME,
            mapping_comment VARCHAR(255)
        )
    END
ELSE
    DELETE FROM leaf_scratch.concept_map_for_loading

INSERT INTO leaf_scratch.concept_map_for_loading(source_concept_code,
                                                 source_concept_name,
                                                 source_concept_vocabulary_id,
                                                 target_concept_id,
                                                 target_concept_code,
                                                 target_concept_name,
                                                 target_concept_vocabulary_id,
                                                 mapping_creation_user,
                                                 mapping_creation_datetime)
SELECT Epic_concept_code,
       Epic_concept_name,
       'EPIC EDG .1',
       concept_SNOMED.concept_id,
       SNOMED_concept_code,
       SNOMED_concept_name,
       'SNOMED',
       'Arthur Goldberg''s conditions.sql script',
       GETDATE()
FROM leaf_scratch.diagnosis_map,
     omop.cdm_std.concept concept_SNOMED
WHERE concept_SNOMED.vocabulary_id = 'SNOMED'
      AND concept_SNOMED.concept_code = SNOMED_concept_code

PRINT ''
