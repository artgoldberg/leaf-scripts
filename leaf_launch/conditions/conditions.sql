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
4. Validate the diagnosis_map
5. Create concept_map_for_loading table by augmenting the diagnosis_map
*/

/*
Formatting todos:
    clean up SQL text case
    standardize SQL indentation
    put commas at end of line, where they belong
    change 'manual mappings' to 'curated mappings'
    clean up comments
*/


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

-- Obtain and report number of Epic id that maps 1-to-many to ICD10 codes in Caboodle
DECLARE @CARDINALITY_EPIC_TO_ICD10 TABLE (EPIC_CONCEPT_CODE NVARCHAR(50) PRIMARY KEY,
                                          NUM_ICD10_CONCEPT_CODES INT)

INSERT INTO @CARDINALITY_EPIC_TO_ICD10
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

DECLARE @NUM_1_TO_MANY_MAPPINGS INT = (SELECT COUNT(*)
                                       FROM @CARDINALITY_EPIC_TO_ICD10
                                       WHERE 1 < [@CARDINALITY_EPIC_TO_ICD10].NUM_ICD10_CONCEPT_CODES)
PRINT 'Ignoring ' + CAST(@NUM_1_TO_MANY_MAPPINGS AS VARCHAR) + ' Epic diagnosis codes that map 1-to-many to ICD10 in Epic'

-- Insert Epic diagnosis codes that map 1-to-1 to ICD10
INSERT INTO rpt.LEAF_SCRATCH.diagnosis_map (EPIC_CONCEPT_CODE, EPIC_CONCEPT_NAME, ICD10_CONCEPT_CODE,
    ICD10_CONCEPT_NAME, SOURCES)
SELECT DiagnosisDim.DiagnosisEpicId, DiagnosisDim.name, DTD.Value, DTD.DisplayString, 'Caboodle'
FROM src.caboodle.DiagnosisDim DiagnosisDim
    INNER JOIN caboodle.DiagnosisTerminologyDim DTD ON DiagnosisDim.DiagnosisKey = DTD.DiagnosisKey
WHERE DTD.[Type] = 'ICD-10-CM'
    -- Avoid non-Clarity data added by Population Health
    AND DTD._HasSourceClarity = 1 AND DTD._IsDeleted = 0
    AND DiagnosisDim._HasSourceClarity = 1 AND DiagnosisDim._IsDeleted = 0
    -- Use Epic diagnosis codes that map 1-to-1 to ICD10
    AND DiagnosisDim.DiagnosisEpicId IN (SELECT EPIC_CONCEPT_CODE
                                         FROM @CARDINALITY_EPIC_TO_ICD10
                                         WHERE [@CARDINALITY_EPIC_TO_ICD10].NUM_ICD10_CONCEPT_CODES = 1)
    -- Get active diagnoses
    AND DiagnosisDim.DiagnosisEpicId IN (SELECT DISTINCT DiagnosisKey
                                         FROM src.caboodle.DiagnosisEventFact)
    -- Don't map to ICD-10-CM IMO0001, which codes for 'Reserved for inherently not codable concepts without codable children'
    -- or to IMO0002, 'Reserved for concepts with insufficient information to code with codable children'
    AND NOT DTD.Value IN('IMO0001', 'IMO0002');

-- 2. Incorporate mappings from ICD-10-CM to SNOMED, from Athena's reference data

UPDATE rpt.LEAF_SCRATCH.diagnosis_map
SET SNOMED_CONCEPT_CODE = concept_SNOMED.concept_code
    ,SNOMED_CONCEPT_NAME = concept_SNOMED.CONCEPT_NAME
FROM omop.cdm_std.CONCEPT_RELATIONSHIP cr
    ,omop.cdm_std.CONCEPT concept_ICD10
    ,omop.cdm_std.CONCEPT concept_SNOMED
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
FROM omop.cdm_std.CONCEPT_RELATIONSHIP cr
    ,omop.cdm_std.CONCEPT concept_EPIC
    ,omop.cdm_std.CONCEPT concept_SNOMED
WHERE
    concept_EPIC.VOCABULARY_ID = 'EPIC EDG .1'
    AND cr.RELATIONSHIP_ID = 'Maps to'
    AND concept_SNOMED.VOCABULARY_ID = 'SNOMED'
    AND concept_EPIC.CONCEPT_ID = cr.CONCEPT_ID_1
    AND concept_SNOMED.CONCEPT_ID = cr.CONCEPT_ID_2

DECLARE @NUM_MANUAL_MAPPINGS INT = (SELECT COUNT(*) FROM #MANUAL_MAPPINGS)
PRINT CAST(@NUM_MANUAL_MAPPINGS AS VARCHAR) + ' manual mappings from EPIC EDG .1 to SNOMED found in cdm_std'

-- The manual mappings of 'Epic diagnosis ID' to SNOMED contain 1-to-many mappings; record and ignore them
DECLARE @CARDINALITY_MANUAL_MAPPINGS TABLE (EPIC_CONCEPT_CODE NVARCHAR(50) PRIMARY KEY,
                                            NUM_SNOMED_CONCEPT_CODES INT)
INSERT INTO @CARDINALITY_MANUAL_MAPPINGS
SELECT EPIC_CONCEPT_CODE, COUNT(SNOMED_CONCEPT_CODE) NUM_SNOMED_CONCEPT_CODES
    FROM #MANUAL_MAPPINGS
    GROUP BY EPIC_CONCEPT_CODE

SELECT #MANUAL_MAPPINGS.EPIC_CONCEPT_CODE,
       #MANUAL_MAPPINGS.EPIC_CONCEPT_NAME,
       #MANUAL_MAPPINGS.SNOMED_CONCEPT_CODE,
       #MANUAL_MAPPINGS.SNOMED_CONCEPT_NAME
    FROM @CARDINALITY_MANUAL_MAPPINGS,
         #MANUAL_MAPPINGS
    WHERE [@CARDINALITY_MANUAL_MAPPINGS].EPIC_CONCEPT_CODE = #MANUAL_MAPPINGS.EPIC_CONCEPT_CODE
          AND 1 < NUM_SNOMED_CONCEPT_CODES
    ORDER BY #MANUAL_MAPPINGS.EPIC_CONCEPT_CODE

DELETE
FROM #MANUAL_MAPPINGS
WHERE EPIC_CONCEPT_CODE IN (SELECT EPIC_CONCEPT_CODE
                            FROM @CARDINALITY_MANUAL_MAPPINGS
                            WHERE 1 < NUM_SNOMED_CONCEPT_CODES)

DECLARE @NUM_MANUAL_MAPPINGS_2 INT = (SELECT COUNT(*) FROM #MANUAL_MAPPINGS)
PRINT CAST(@NUM_MANUAL_MAPPINGS_2 AS VARCHAR) + ' 1-to-1 manual mappings from EPIC EDG .1 to SNOMED found in cdm_std'


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
    ,omop.cdm_std.CONCEPT_RELATIONSHIP cr
    ,omop.cdm_std.CONCEPT concept_ICD10
    ,omop.cdm_std.CONCEPT concept_SNOMED
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
FROM rpt.LEAF_SCRATCH.diagnosis_map diagnosis_map
    ,omop.cdm_std.CONCEPT_RELATIONSHIP cr
    ,omop.cdm_std.CONCEPT concept_ICD10
    ,omop.cdm_std.CONCEPT concept_SNOMED
WHERE diagnosis_map.HAND_MAP_STATUS = 'MISSING'
    -- get records in CONCEPT_RELATIONSHIP that map from ICD-10-CM to SNOMED
    AND concept_ICD10.VOCABULARY_ID = 'ICD10CM'
    AND concept_SNOMED.VOCABULARY_ID = 'SNOMED'
    AND cr.RELATIONSHIP_ID = 'Maps to'
    AND concept_ICD10.CONCEPT_ID = cr.CONCEPT_ID_1
    AND concept_SNOMED.CONCEPT_ID = cr.CONCEPT_ID_2
    AND diagnosis_map.SNOMED_CONCEPT_CODE = concept_SNOMED.concept_code;

-- 4. Validate the diagnosis_map
-- Ensure that there are no NULLs values for ICD10 or SNOMED codes, so all EPIC codes can be fully mapped
-- Count and then remove records containing SNOMED codes that do not contain a mapping to ICD-10-CM in CONCEPT_RELATIONSHIP
DECLARE @NUM_ICD10_NULLS INT = (SELECT COUNT(*)
                                FROM rpt.LEAF_SCRATCH.diagnosis_map
                                WHERE ICD10_CONCEPT_CODE IS NULL)
PRINT 'Deleting ' + CAST(@NUM_ICD10_NULLS AS VARCHAR) + ' records that lack an ICD-10-CM code'

DELETE
FROM rpt.LEAF_SCRATCH.diagnosis_map
WHERE ICD10_CONCEPT_CODE IS NULL

-- Count and then remove records missing SNOMED codes
DECLARE @NUM_SNOMED_NULLS INT = (SELECT COUNT(*)
                                FROM rpt.LEAF_SCRATCH.diagnosis_map
                                WHERE SNOMED_CONCEPT_CODE IS NULL)
PRINT 'Deleting ' + CAST(@NUM_SNOMED_NULLS AS VARCHAR) + ' records that lack a SNOMED code'

DELETE
FROM rpt.LEAF_SCRATCH.diagnosis_map
WHERE SNOMED_CONCEPT_CODE IS NULL;

-- Ensure that all EPIC EDG .1 → SNOMED are 1-to-1, so condition_concept_id can be unambiguously initialized
DECLARE @CARDINALITY_EPIC_2_SNOMED_MAPPINGS TABLE (EPIC_CONCEPT_CODE NVARCHAR(50) PRIMARY KEY,
                                                   NUM_SNOMED_CONCEPT_CODES INT)
INSERT INTO @CARDINALITY_EPIC_2_SNOMED_MAPPINGS
SELECT EPIC_CONCEPT_CODE, COUNT(SNOMED_CONCEPT_CODE)
    FROM rpt.LEAF_SCRATCH.diagnosis_map
    GROUP BY EPIC_CONCEPT_CODE
IF EXISTS (SELECT *
           FROM @CARDINALITY_EPIC_2_SNOMED_MAPPINGS
           WHERE 1 < NUM_SNOMED_CONCEPT_CODES)
BEGIN
   DECLARE @MSG VARCHAR = 'Some EPIC EDG .1 to SNOMED mappings are 1-to-many, so condition_concept_id cannot be unambiguously initialized'
   RAISERROR(@MSG, 16, 0)
END

-- Count the unique ICD10 codes in the diagnosis_map
DECLARE @NUM_ICD10_CODES INT = (SELECT COUNT(DISTINCT ICD10_CONCEPT_CODE)
                                FROM rpt.LEAF_SCRATCH.diagnosis_map)
PRINT CAST(@NUM_ICD10_CODES AS VARCHAR) + ' unique ICD10 codes found'

-- 5. Create concept_map_for_loading table by augmenting the diagnosis_map with dependant attributes of each concept, and metadata
USE rpt;

IF (NOT EXISTS (SELECT *
                FROM INFORMATION_SCHEMA.TABLES
                WHERE TABLE_SCHEMA = 'LEAF_SCRATCH'
                AND TABLE_NAME = 'concept_map_for_loading'))
    BEGIN
        CREATE TABLE LEAF_SCRATCH.concept_map_for_loading
        (
            SOURCE_CONCEPT_CODE VARCHAR(50) NOT NULL,
            SOURCE_CONCEPT_NAME VARCHAR(255) NOT NULL,
            SOURCE_CONCEPT_VOCABULARY_ID VARCHAR(50) NOT NULL,
            VALUE_AS_SOURCE_CONCEPT_CODE BIGINT,
            VALUE_AS_SOURCE_CONCEPT_NAME VARCHAR(255),
            VALUE_AS_SOURCE_CONCEPT_VOCABULARY_ID VARCHAR(50),
            TARGET_CONCEPT_ID BIGINT NOT NULL,
            TARGET_CONCEPT_CODE VARCHAR(50) NOT NULL,
            TARGET_CONCEPT_NAME VARCHAR(255) NOT NULL,
            TARGET_CONCEPT_VOCABULARY_ID VARCHAR(50) NOT NULL,
            TARGET_VALUE_AS_CONCEPT_ID BIGINT,
            TARGET_VALUE_AS_CONCEPT_CODE VARCHAR(50),
            TARGET_VALUE_AS_CONCEPT_NAME VARCHAR(255),
            TARGET_VALUE_AS_CONCEPT_VOCABULARY_ID VARCHAR(50),
            TARGET_VALUE_AS_NUMBER BIGINT,
            TARGET_UNIT_CONCEPT_ID BIGINT,
            TARGET_UNIT_CONCEPT_CODE VARCHAR(50),
            TARGET_UNIT_CONCEPT_NAME VARCHAR(255),
            TARGET_UNIT_CONCEPT_VOCABULARY_ID VARCHAR(50),
            TARGET_QUALIFIER_CONCEPT_ID VARCHAR(50),
            TARGET_QUALIFIER_CONCEPT_CODE VARCHAR(50),
            TARGET_QUALIFIER_CONCEPT_NAME VARCHAR(255),
            TARGET_QUALIFIER_CONCEPT_VOCABULARY_ID VARCHAR(50),
            MAPPING_EQUIVALENCE VARCHAR(50),
            MAPPING_CREATION_USER VARCHAR(50) NOT NULL,
            MAPPING_CREATION_DATETIME datetime NOT NULL,
            MAPPING_STATUS VARCHAR(50),
            MAPPING_STATUS_USER VARCHAR(50),
            MAPPING_STATUS_DATETIME datetime,
            MAPPING_COMMENT VARCHAR(255)
        )
    END
ELSE
    DELETE FROM LEAF_SCRATCH.concept_map_for_loading

INSERT INTO LEAF_SCRATCH.concept_map_for_loading(SOURCE_CONCEPT_CODE,
                                                 SOURCE_CONCEPT_NAME,
                                                 SOURCE_CONCEPT_VOCABULARY_ID,
                                                 TARGET_CONCEPT_ID,
                                                 TARGET_CONCEPT_CODE,
                                                 TARGET_CONCEPT_NAME,
                                                 TARGET_CONCEPT_VOCABULARY_ID,
                                                 MAPPING_CREATION_USER,
                                                 MAPPING_CREATION_DATETIME)
SELECT EPIC_CONCEPT_CODE,
       EPIC_CONCEPT_NAME,
       'EPIC EDG .1',
       concept_SNOMED.concept_id,
       SNOMED_CONCEPT_CODE,
       SNOMED_CONCEPT_NAME,
       'SNOMED',
       'Arthur Goldberg''s conditions.sql script',
       GETDATE()
FROM LEAF_SCRATCH.diagnosis_map,
     omop.cdm_std.CONCEPT concept_SNOMED
WHERE concept_SNOMED.VOCABULARY_ID = 'SNOMED'
      AND concept_SNOMED.concept_code = SNOMED_CONCEPT_CODE

PRINT ''
