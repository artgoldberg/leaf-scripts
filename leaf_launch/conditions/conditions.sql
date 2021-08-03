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
3a. If manual mapping is consistent, mark diagnosis_map.HAND_MAP_STATUS 'CONSISTENT'
3b. If manual mapping conflicts, mark diagnosis_map.HAND_MAP_STATUS 'CONFLICTED',
    use the manual value selected for SNOMED, and the ICD-10-CM value that implies, and update SOURCES
3c. If manual mapping is missing, mark diagnosis_map.HAND_MAP_STATUS 'MISSING',
    add 'Epic diagnosis ID' ICD-10-CM and SNOMED values, and update SOURCES
4. Create concept_map_for_loading table by augmenting #5 with dependant attributes of each concept, and metadata
*/

-- TODO: clean up text case
-- TODO: change 'manual mappings' to 'curated'
-- TODO: clean up comments

-- 0. Create diagnosis_map table
-- Schema for table mapping diagnosis concept ids

PRINT 'Starting ''conditions.sql'' at ' + CONVERT(varchar, GETDATE(), 120)

USE rpt;

IF (NOT EXISTS (SELECT *
                 FROM INFORMATION_SCHEMA.TABLES
                 WHERE TABLE_SCHEMA = 'LEAF_SCRATCH'
                 AND TABLE_NAME = 'diagnosis_map'))
    BEGIN
        CREATE TABLE LEAF_SCRATCH.diagnosis_map
        (
            EPIC_CONCEPT_CODE NVARCHAR(50) NOT NULL PRIMARY KEY,
            EPIC_CONCEPT_NAME NVARCHAR(255) NOT NULL,
            ICD10_CONCEPT_CODE NVARCHAR(50),
            ICD10_CONCEPT_NAME NVARCHAR(255),
            SNOMED_CONCEPT_CODE NVARCHAR(50),
            SNOMED_CONCEPT_NAME NVARCHAR(255),
            -- Relationship of Sharon's hand-coded Epic -> SNOMED mapping to automated mapping
            HAND_MAP_STATUS NVARCHAR(50),
            SOURCES NVARCHAR(200) NOT NULL,     -- Sources for a record
            COMMENT NVARCHAR(200)
        )
    END
ELSE
    DELETE FROM LEAF_SCRATCH.diagnosis_map


-- 1. Map 'Epic diagnosis ID' to ICD-10-CM, from the Epic concept tables in src
-- Filter to Epic codes that map 1-to-1 to ICD10 and have been used in clinical events

USE src;

-- Get count of mapped ICD10 codes for each Epic id
-- TODO: report number Epic diagnosis codes that map 1-to-many to ICD10 in Epic
-- Make temp table for the Epic ID -> ICD10 frequencies
-- IF OBJECT_ID(N'tempdb..#EPIC_ID_MAP_FREQ') IS NOT NULL
-- 	DROP TABLE #EPIC_ID_MAP_FREQ
-- CREATE TABLE #EPIC_ID_MAP_FREQ(
--     EPIC_CONCEPT_CODE NVARCHAR(50) NOT NULL,
--     NUM_ICD10_CODES INT NOT NULL)

-- INSERT INTO #EPIC_ID_MAP_FREQ(EPIC_CONCEPT_CODE, NUM_ICD10_CODES)
-- SELECT DiagnosisDim.DiagnosisEpicId, COUNT(DTD.Value) num_ICD10_codes
-- FROM src.caboodle.DiagnosisDim DiagnosisDim
--     INNER JOIN caboodle.DiagnosisTerminologyDim DTD ON DiagnosisDim.DiagnosisKey = DTD.DiagnosisKey
-- WHERE DTD.[Type] = 'ICD-10-CM'
-- -- avoid non-Clarity data added by Population Health
-- AND DTD._HasSourceClarity = 1 AND DTD._IsDeleted = 0
-- AND DiagnosisDim._HasSourceClarity = 1 AND DiagnosisDim._IsDeleted = 0
-- GROUP BY DiagnosisDim.DiagnosisEpicId

WITH epic_id_map_freq AS
    (SELECT DiagnosisDim.DiagnosisEpicId, COUNT(DTD.Value) num_ICD10_codes
    FROM src.caboodle.DiagnosisDim DiagnosisDim
         INNER JOIN caboodle.DiagnosisTerminologyDim DTD ON DiagnosisDim.DiagnosisKey = DTD.DiagnosisKey
    WHERE DTD.[Type] = 'ICD-10-CM'
    -- avoid non-Clarity data added by Population Health
    AND DTD._HasSourceClarity = 1 AND DTD._IsDeleted = 0
    AND DiagnosisDim._HasSourceClarity = 1 AND DiagnosisDim._IsDeleted = 0
    GROUP BY DiagnosisDim.DiagnosisEpicId)

-- DECLARE @NUM_1_TO_MANY_MAPPINGS INT = (SELECT COUNT(*) FROM #MANUAL_MAPPINGS)
-- PRINT 'Ignoring ' + CAST(@NUM_1_TO_MANY_MAPPINGS AS VARCHAR) + ' Epic diagnosis codes that map 1-to-many to ICD10 in Epic';

-- insert Epic diagnosis codes that map 1-to-1 to ICD10
INSERT INTO rpt.LEAF_SCRATCH.diagnosis_map (EPIC_CONCEPT_CODE, EPIC_CONCEPT_NAME, ICD10_CONCEPT_CODE,
    ICD10_CONCEPT_NAME, SOURCES)
SELECT DiagnosisDim.DiagnosisEpicId, DiagnosisDim.name, DTD.Value, DTD.DisplayString, 'Caboodle'
FROM src.caboodle.DiagnosisDim DiagnosisDim
    INNER JOIN caboodle.DiagnosisTerminologyDim DTD ON DiagnosisDim.DiagnosisKey = DTD.DiagnosisKey
WHERE DTD.[Type] = 'ICD-10-CM'
    -- avoid non-Clarity data added by Population Health
    AND DTD._HasSourceClarity = 1 AND DTD._IsDeleted = 0
    AND DiagnosisDim._HasSourceClarity = 1 AND DiagnosisDim._IsDeleted = 0
    -- use Epic diagnosis codes that map 1-to-1 to ICD10
    AND DiagnosisDim.DiagnosisEpicId IN (SELECT DiagnosisEpicId
                                         FROM epic_id_map_freq
                                         WHERE epic_id_map_freq.num_ICD10_codes = 1)
    -- get active diagnoses
    AND DiagnosisDim.DiagnosisEpicId IN (SELECT DISTINCT DiagnosisKey
                                         FROM src.caboodle.DiagnosisEventFact)


-- 2. Incorporate mappings from ICD-10-CM to SNOMED, from Athena's reference data
USE omop;

UPDATE rpt.LEAF_SCRATCH.diagnosis_map
SET SNOMED_CONCEPT_CODE = concept_SNOMED.concept_code
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
    AND rpt.LEAF_SCRATCH.diagnosis_map.ICD10_CONCEPT_CODE = concept_ICD10.concept_code;


-- 3. Integrate Sharon's existing manual mappings of 'Epic diagnosis ID' to SNOMED, from concept_relationship
-- Make temp table for the manual mappings
IF OBJECT_ID(N'tempdb..#MANUAL_MAPPINGS') IS NOT NULL
	DROP TABLE #MANUAL_MAPPINGS
CREATE TABLE #MANUAL_MAPPINGS(
    EPIC_CONCEPT_CODE NVARCHAR(50) NOT NULL,
    EPIC_CONCEPT_NAME NVARCHAR(255) NOT NULL,
    SNOMED_CONCEPT_CODE NVARCHAR(50) NOT NULL,
    SNOMED_CONCEPT_NAME NVARCHAR(255)
)

INSERT INTO #MANUAL_MAPPINGS
SELECT concept_EPIC.concept_code
    ,concept_EPIC.concept_name
    ,concept_SNOMED.concept_code
    ,concept_SNOMED.concept_name
FROM cdm_std.CONCEPT_RELATIONSHIP cr
    ,cdm_std.CONCEPT concept_EPIC
    ,cdm_std.CONCEPT concept_SNOMED
WHERE
    concept_EPIC.VOCABULARY_ID = 'EPIC EDG .1'
    AND cr.RELATIONSHIP_ID = 'Maps to'
    AND concept_SNOMED.VOCABULARY_ID = 'SNOMED'
    AND concept_EPIC.CONCEPT_ID = cr.CONCEPT_ID_1
    AND concept_SNOMED.CONCEPT_ID = cr.CONCEPT_ID_2

DECLARE @NUM_MANUAL_MAPPINGS INT = (SELECT COUNT(*) FROM #MANUAL_MAPPINGS)
PRINT CAST(@NUM_MANUAL_MAPPINGS AS VARCHAR) + ' manual mappings from EPIC EDG .1 to SNOMED found in cdm_std';

-- Surprisingly, the manual mappings of 'Epic diagnosis ID' to SNOMED contain 1-to-many mappings; ignore them
WITH EPIC_CONCEPT_CODE_FREQ AS
    (SELECT EPIC_CONCEPT_CODE, COUNT(SNOMED_CONCEPT_CODE) NUM_SNOMED_CONCEPT_CODES
     FROM #MANUAL_MAPPINGS
     GROUP BY EPIC_CONCEPT_CODE)

    DELETE
    FROM #MANUAL_MAPPINGS
    WHERE EPIC_CONCEPT_CODE IN (SELECT EPIC_CONCEPT_CODE
                                FROM EPIC_CONCEPT_CODE_FREQ
                                WHERE 1 < NUM_SNOMED_CONCEPT_CODES)

DECLARE @NUM_MANUAL_MAPPINGS INT = (SELECT COUNT(*) FROM #MANUAL_MAPPINGS)
PRINT CAST(@NUM_MANUAL_MAPPINGS AS VARCHAR) + ' 1-to-1 manual mappings from EPIC EDG .1 to SNOMED found in cdm_std'


-- 3a. If manual mapping is consistent, mark diagnosis_map.HAND_MAP_STATUS as 'CONSISTENT', and update SOURCES
UPDATE rpt.LEAF_SCRATCH.diagnosis_map
SET HAND_MAP_STATUS = 'CONSISTENT'
    ,SOURCES = 'Caboodle and MANUAL'
FROM #MANUAL_MAPPINGS
    ,rpt.LEAF_SCRATCH.diagnosis_map diagnosis_map
WHERE diagnosis_map.EPIC_CONCEPT_CODE = #MANUAL_MAPPINGS.EPIC_CONCEPT_CODE
    AND diagnosis_map.SNOMED_CONCEPT_CODE = #MANUAL_MAPPINGS.SNOMED_CONCEPT_CODE


-- 3b. If manual mapping conflicts, mark diagnosis_map.HAND_MAP_STATUS 'CONFLICTED',
--     use the manual value for SNOMED, the ICD-10-CM value that implies, and update SOURCES
UPDATE rpt.LEAF_SCRATCH.diagnosis_map
SET HAND_MAP_STATUS = 'CONFLICTED'
    ,SNOMED_CONCEPT_CODE = #MANUAL_MAPPINGS.SNOMED_CONCEPT_CODE
    ,SNOMED_CONCEPT_NAME = #MANUAL_MAPPINGS.SNOMED_CONCEPT_NAME
    ,SOURCES = 'MANUAL'
FROM #MANUAL_MAPPINGS
    ,rpt.LEAF_SCRATCH.diagnosis_map diagnosis_map
WHERE diagnosis_map.EPIC_CONCEPT_CODE = #MANUAL_MAPPINGS.EPIC_CONCEPT_CODE
    AND NOT diagnosis_map.SNOMED_CONCEPT_CODE = #MANUAL_MAPPINGS.SNOMED_CONCEPT_CODE

-- 3b continued; insert the ICD-10-CM value associated with the manually mapped value for SNOMED
UPDATE rpt.LEAF_SCRATCH.diagnosis_map
SET ICD10_CONCEPT_CODE = concept_ICD10.concept_code
    ,ICD10_CONCEPT_NAME = concept_ICD10.CONCEPT_NAME
FROM #MANUAL_MAPPINGS
    ,rpt.LEAF_SCRATCH.diagnosis_map diagnosis_map
    ,cdm_std.CONCEPT_RELATIONSHIP cr
    ,cdm_std.CONCEPT concept_ICD10
    ,cdm_std.CONCEPT concept_SNOMED
WHERE diagnosis_map.SOURCES = 'MANUAL'
    -- get records in CONCEPT_RELATIONSHIP that map from ICD-10-CM to SNOMED
    AND concept_ICD10.VOCABULARY_ID = 'ICD10CM'
    AND concept_SNOMED.VOCABULARY_ID = 'SNOMED'
    AND cr.RELATIONSHIP_ID = 'Maps to'
    AND concept_ICD10.CONCEPT_ID = cr.CONCEPT_ID_1
    AND concept_SNOMED.CONCEPT_ID = cr.CONCEPT_ID_2
    AND diagnosis_map.SNOMED_CONCEPT_CODE = concept_SNOMED.concept_code


-- 3c. If manual mapping is missing, insert diagnosis_map record with HAND_MAP_STATUS = 'MISSING',
--     'Epic diagnosis ID', SNOMED values from manual mappings, and SOURCES
DECLARE @NUM_MAPPINGS_LEFT INT = (SELECT COUNT(*)
                                  FROM #MANUAL_MAPPINGS
                                  WHERE #MANUAL_MAPPINGS.EPIC_CONCEPT_CODE
                                  NOT IN(SELECT diagnosis_map.EPIC_CONCEPT_CODE
                                         FROM rpt.LEAF_SCRATCH.diagnosis_map diagnosis_map))
PRINT CAST(@NUM_MAPPINGS_LEFT AS VARCHAR) + ' manual mappings of EPIC to SNOMED are not found in Caboodle'

INSERT INTO rpt.LEAF_SCRATCH.diagnosis_map(EPIC_CONCEPT_CODE
                                           ,EPIC_CONCEPT_NAME
                                           ,SNOMED_CONCEPT_CODE
                                           ,SNOMED_CONCEPT_NAME
                                           ,HAND_MAP_STATUS
                                           ,SOURCES)
SELECT #MANUAL_MAPPINGS.EPIC_CONCEPT_CODE
    ,#MANUAL_MAPPINGS.EPIC_CONCEPT_NAME
    ,#MANUAL_MAPPINGS.SNOMED_CONCEPT_CODE
    ,#MANUAL_MAPPINGS.SNOMED_CONCEPT_NAME
    ,'MISSING'
    ,'MANUAL MAPPINGS'
FROM #MANUAL_MAPPINGS
WHERE #MANUAL_MAPPINGS.EPIC_CONCEPT_CODE NOT IN (SELECT EPIC_CONCEPT_CODE
                                                 FROM rpt.LEAF_SCRATCH.diagnosis_map)

-- 3c continued; insert the ICD-10-CM value associated with the manually mapped value for SNOMED
UPDATE rpt.LEAF_SCRATCH.diagnosis_map
SET ICD10_CONCEPT_CODE = concept_ICD10.concept_code
    ,ICD10_CONCEPT_NAME = concept_ICD10.CONCEPT_NAME
FROM #MANUAL_MAPPINGS
    ,rpt.LEAF_SCRATCH.diagnosis_map diagnosis_map
    ,cdm_std.CONCEPT_RELATIONSHIP cr
    ,cdm_std.CONCEPT concept_ICD10
    ,cdm_std.CONCEPT concept_SNOMED
WHERE diagnosis_map.HAND_MAP_STATUS = 'MISSING'
    -- get records in CONCEPT_RELATIONSHIP that map from ICD-10-CM to SNOMED
    AND concept_ICD10.VOCABULARY_ID = 'ICD10CM'
    AND concept_SNOMED.VOCABULARY_ID = 'SNOMED'
    AND cr.RELATIONSHIP_ID = 'Maps to'
    AND concept_ICD10.CONCEPT_ID = cr.CONCEPT_ID_1
    AND concept_SNOMED.CONCEPT_ID = cr.CONCEPT_ID_2
    AND diagnosis_map.SNOMED_CONCEPT_CODE = concept_SNOMED.concept_code

-- TODO: make the concept_map_for_loading table

PRINT ''
