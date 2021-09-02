/*
 * Create mappings from 'Epic diagnosis IDs' to SNOMED
 * Results are new entries in the Leaf_usagi.Leaf_staging table
 * Author: Arthur.Goldberg@mssm.edu
 */

/*
Must be executed as goldba06@MSSMCAMPUS.MSSM.EDU.

Steps
0. Create conditions_map table
1. Map 'Epic diagnosis ID' to ICD-10-CM, from the Epic concept tables in src
2. Incorporate mappings from ICD-10-CM to SNOMED, from Athena's reference data
3. Integrate Sharon's existing manual mappings of 'Epic diagnosis ID' to SNOMED, from rpt.Leaf_usagi.mapping_import
3a. If manual mapping is consistent, mark conditions_map.hand_map_status 'CONSISTENT'
3b. If manual mapping conflicts, mark conditions_map.hand_map_status 'CONFLICTED',
    use the manual value selected for SNOMED, and the ICD-10-CM value that implies, and update sources
3c. If manual mapping is missing, mark conditions_map.hand_map_status 'MISSING',
    add 'Epic diagnosis ID' ICD-10-CM and SNOMED values, and update sources
4. Validate the conditions_map
5. Insert new mappings into rpt.Leaf_usagi.Leaf_staging
*/

-- Todo style improvements:
-- clean up comments
-- reduce code duplication


-- 0. Create conditions_map table
-- Schema for table mapping diagnosis concept ids

PRINT 'Starting ''conditions.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120)

USE rpt;

IF (NOT EXISTS (SELECT *
                FROM information_schema.tables
                WHERE table_schema = 'leaf_scratch'
                AND table_name = 'conditions_map'))
    BEGIN
        CREATE TABLE leaf_scratch.conditions_map
        (
            Epic_concept_id INT,
            Epic_concept_code NVARCHAR(50) NOT NULL PRIMARY KEY,
            Epic_concept_name NVARCHAR(255) NOT NULL,
            ICD10_concept_code NVARCHAR(50),
            ICD10_concept_name NVARCHAR(255),
            SNOMED_concept_id INT,
            SNOMED_concept_code NVARCHAR(50),
            SNOMED_concept_name NVARCHAR(255),
            -- Relationship of Sharon's hand-coded Epic -> SNOMED mapping to automated mapping
            hand_map_status NVARCHAR(50),
            sources NVARCHAR(200) NOT NULL,     -- Sources for a record
            comment NVARCHAR(200)
        )
    END
ELSE
    DELETE FROM leaf_scratch.conditions_map


-- 1. Map 'Epic diagnosis ID' to ICD-10-CM, from the Epic concept tables in src
-- Filter to Epic codes that map 1-to-1 to ICD10

USE src;

-- Obtain and report number of Epic ids that maps 1-to-many to ICD10 codes in Caboodle
DECLARE @cardinality_epic_to_icd10 TABLE (Epic_concept_code NVARCHAR(50) PRIMARY KEY,
                                          num_ICD10_concept_codes INT)

INSERT INTO @cardinality_epic_to_icd10
    SELECT DiagnosisDim.DiagnosisEpicId, COUNT(DTD.Value)
    FROM src.caboodle.DiagnosisDim DiagnosisDim
        INNER JOIN caboodle.DiagnosisTerminologyDim DTD
              ON DiagnosisDim.DiagnosisKey = DTD.DiagnosisKey
    WHERE DTD.[Type] = 'ICD-10-CM'
    -- Avoid non-Clarity data added by Population Health
    AND DTD._HasSourceClarity = 1 AND DTD._IsDeleted = 0
    AND DiagnosisDim._HasSourceClarity = 1 AND DiagnosisDim._IsDeleted = 0
    /*
    -- Disable so that all mappings are inserted into concept_relationship
    -- Only get active diagnoses
    AND DiagnosisDim.DiagnosisKey IN (SELECT DISTINCT DiagnosisKey
                                      FROM src.caboodle.DiagnosisEventFact)
     */
    GROUP BY DiagnosisDim.DiagnosisEpicId

DECLARE @num_1_to_many_mappings INT = (SELECT COUNT(*)
                                       FROM @cardinality_epic_to_icd10
                                       WHERE 1 < [@cardinality_epic_to_icd10].num_ICD10_concept_codes)
PRINT 'Ignoring ' + CAST(@num_1_to_many_mappings AS VARCHAR) +
      ' Epic diagnosis codes that map 1-to-many to ICD10 in Epic'

-- Insert Epic diagnosis codes that map 1-to-1 to ICD10
INSERT INTO rpt.leaf_scratch.conditions_map (Epic_concept_code,
                                             Epic_concept_name,
                                             ICD10_concept_code,
                                             ICD10_concept_name,
                                             sources)
SELECT DiagnosisDim.DiagnosisEpicId,
       DiagnosisDim.name,
       DTD.Value,
       DTD.DisplayString,
       'Caboodle'
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
    /*
    -- Disable so that all mappings are inserted into concept_relationship
    -- Only get active diagnoses
    AND DiagnosisDim.DiagnosisKey IN (SELECT DISTINCT DiagnosisKey
                                      FROM src.caboodle.DiagnosisEventFact)
     */
    -- Don't map to ICD-10-CM IMO0001, which codes for 'Reserved for inherently not codable concepts without codable children'
    -- or to IMO0002, 'Reserved for concepts with insufficient information to code with codable children'
    AND NOT DTD.Value IN('IMO0001', 'IMO0002');

-- 2. Incorporate mappings from ICD-10-CM to SNOMED, from Athena's reference data

UPDATE rpt.leaf_scratch.conditions_map
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
    -- join with ICD-10-CM records in leaf_scratch.conditions_map
    AND rpt.leaf_scratch.conditions_map.ICD10_concept_code = concept_ICD10.concept_code;


-- 3. Integrate Sharon's existing manual mappings of 'Epic diagnosis ID' to SNOMED, from rpt.Leaf_usagi.mapping_import
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
SELECT source_concept_code,
       source_concept_name,
       target_concept_code,
       target_concept_name
FROM rpt.Leaf_usagi.mapping_import
WHERE mapping_import.source_concept_vocabulary_id = 'EPIC EDG .1'
      AND target_concept_vocabulary_id = 'SNOMED'
      -- Constraint on 'Sharon Nirenberg' probably excessive; want anyone to be able to make hand maps Epic EDG -> SNOMED
      AND mapping_creation_user = 'Sharon Nirenberg'


DECLARE @num_manual_mappings INT = (SELECT COUNT(*) FROM #manual_mappings)
PRINT CAST(@num_manual_mappings AS VARCHAR) +
    ' manual mappings from EPIC EDG .1 to SNOMED found in rpt.Leaf_usagi.mapping_import'

-- The manual mappings of 'Epic diagnosis ID' to SNOMED contain 1-to-many mappings; record and ignore them
DECLARE @cardinality_manual_mappings TABLE (Epic_concept_code NVARCHAR(50) PRIMARY KEY,
                                            num_SNOMED_concept_codes INT)
INSERT INTO @cardinality_manual_mappings
SELECT Epic_concept_code, COUNT(SNOMED_concept_code) num_SNOMED_concept_codes
FROM #manual_mappings
GROUP BY Epic_concept_code

-- Generate conditions/limitations/1-to-many_manual_mappings_Epic_to_SNOMED.csv
SELECT #manual_mappings.Epic_concept_code,
       #manual_mappings.Epic_concept_name,
       #manual_mappings.SNOMED_concept_code,
       #manual_mappings.SNOMED_concept_name
FROM @cardinality_manual_mappings,
     #manual_mappings
WHERE [@cardinality_manual_mappings].Epic_concept_code = #manual_mappings.Epic_concept_code
      AND 1 < num_SNOMED_concept_codes
ORDER BY #manual_mappings.Epic_concept_code

-- Delete 1-to-many manual mappings
DELETE
FROM #manual_mappings
WHERE Epic_concept_code IN (SELECT Epic_concept_code
                            FROM @cardinality_manual_mappings
                            WHERE 1 < num_SNOMED_concept_codes)

DECLARE @num_manual_mappings_2 INT = (SELECT COUNT(*) FROM #manual_mappings)
PRINT CAST(@num_manual_mappings_2 AS VARCHAR) +
    ' 1-to-1 manual mappings from EPIC EDG .1 to SNOMED found in rpt.Leaf_usagi.mapping_import'


-- 3a. If manual mapping is consistent with conditions_map, mark conditions_map.hand_map_status as 'CONSISTENT', and update sources

UPDATE rpt.leaf_scratch.conditions_map
SET hand_map_status = 'CONSISTENT',
    sources = 'Caboodle and MANUAL'
FROM #manual_mappings,
     rpt.leaf_scratch.conditions_map conditions_map
WHERE conditions_map.Epic_concept_code = #manual_mappings.Epic_concept_code
      AND conditions_map.SNOMED_concept_code = #manual_mappings.SNOMED_concept_code


-- 3b. If manual mapping conflicts, mark conditions_map.hand_map_status 'CONFLICTED',
--     use the manual value for SNOMED, the ICD-10-CM value that implies, and update sources
UPDATE rpt.leaf_scratch.conditions_map
SET hand_map_status = 'CONFLICTED',
    SNOMED_concept_code = #manual_mappings.SNOMED_concept_code,
    SNOMED_concept_name = #manual_mappings.SNOMED_concept_name,
    sources = 'MANUAL'
FROM #manual_mappings,
     rpt.leaf_scratch.conditions_map conditions_map
WHERE conditions_map.Epic_concept_code = #manual_mappings.Epic_concept_code
      AND NOT conditions_map.SNOMED_concept_code = #manual_mappings.SNOMED_concept_code

-- 3b continued; insert the ICD-10-CM value associated with the manually mapped value for SNOMED
UPDATE rpt.leaf_scratch.conditions_map
SET ICD10_concept_code = concept_ICD10.concept_code,
    ICD10_concept_name = concept_ICD10.concept_name
FROM #manual_mappings,
     rpt.leaf_scratch.conditions_map conditions_map,
     omop.cdm_std.concept_relationship cr,
     omop.cdm_std.concept concept_ICD10,
     omop.cdm_std.concept concept_SNOMED
WHERE conditions_map.sources = 'MANUAL'
    -- get records in CONCEPT_RELATIONSHIP that map from ICD-10-CM to SNOMED
    AND concept_ICD10.vocabulary_id = 'ICD10CM'
    AND concept_SNOMED.vocabulary_id = 'SNOMED'
    AND cr.relationship_id = 'Maps to'
    AND concept_ICD10.concept_id = cr.concept_id_1
    AND concept_SNOMED.concept_id = cr.concept_id_2
    AND conditions_map.SNOMED_concept_code = concept_SNOMED.concept_code


-- 3c. If manual mapping is missing, insert conditions_map record with hand_map_status = 'MISSING',
--     'Epic diagnosis ID', SNOMED values from manual mappings, and sources
DECLARE @num_mappings_left INT = (SELECT COUNT(*)
                                  FROM #manual_mappings
                                  WHERE #manual_mappings.Epic_concept_code
                                  NOT IN(SELECT conditions_map.Epic_concept_code
                                         FROM rpt.leaf_scratch.conditions_map conditions_map))
PRINT CAST(@num_mappings_left AS VARCHAR) + ' manual mappings of EPIC to SNOMED are not found in Caboodle'

INSERT INTO rpt.leaf_scratch.conditions_map(Epic_concept_code,
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
       'MANUAL'
FROM #manual_mappings
WHERE #manual_mappings.Epic_concept_code NOT IN (SELECT Epic_concept_code
                                                 FROM rpt.leaf_scratch.conditions_map)

-- 3c continued; insert the ICD-10-CM value associated with the manually mapped value for SNOMED
UPDATE rpt.leaf_scratch.conditions_map
SET ICD10_concept_code = concept_ICD10.concept_code,
    ICD10_concept_name = concept_ICD10.concept_name
FROM rpt.leaf_scratch.conditions_map conditions_map,
    omop.cdm_std.concept_relationship cr,
    omop.cdm_std.concept concept_ICD10,
    omop.cdm_std.concept concept_SNOMED
WHERE conditions_map.hand_map_status = 'MISSING'
    -- get records in CONCEPT_RELATIONSHIP that map from ICD-10-CM to SNOMED
    AND concept_ICD10.vocabulary_id = 'ICD10CM'
    AND concept_SNOMED.vocabulary_id = 'SNOMED'
    AND cr.relationship_id = 'Maps to'
    AND concept_ICD10.concept_id = cr.concept_id_1
    AND concept_SNOMED.concept_id = cr.concept_id_2
    AND conditions_map.SNOMED_concept_code = concept_SNOMED.concept_code;

-- 4. Validate the conditions_map
-- Ensure that there are no NULLs values for ICD10 or SNOMED codes, so all EPIC codes can be fully mapped
DECLARE @num_icd10_nulls INT = (SELECT COUNT(*)
                                FROM rpt.leaf_scratch.conditions_map
                                WHERE ICD10_concept_code IS NULL)
PRINT 'Deleting ' + CAST(@num_icd10_nulls AS VARCHAR) + ' records that lack an ICD-10-CM code'

DELETE
FROM rpt.leaf_scratch.conditions_map
WHERE ICD10_concept_code IS NULL

-- Count and then remove records containing SNOMED codes that do not contain a mapping to ICD-10-CM in CONCEPT_RELATIONSHIP
DECLARE @num_snomed_nulls INT = (SELECT COUNT(*)
                                 FROM rpt.leaf_scratch.conditions_map
                                 WHERE SNOMED_concept_code IS NULL)
PRINT 'Deleting ' + CAST(@num_snomed_nulls AS VARCHAR) + ' records that lack a SNOMED code'

DELETE
FROM rpt.leaf_scratch.conditions_map
WHERE SNOMED_concept_code IS NULL;

-- Enrich conditions_map with concept ids
UPDATE rpt.leaf_scratch.conditions_map
SET Epic_concept_id = concept_Epic.concept_id
FROM omop.cdm_std.concept concept_Epic,
     rpt.leaf_scratch.conditions_map
WHERE concept_Epic.concept_code = Epic_concept_code
      AND concept_Epic.vocabulary_id = 'EPIC EDG .1'

UPDATE rpt.leaf_scratch.conditions_map
SET SNOMED_concept_id = concept_SNOMED.concept_id
FROM omop.cdm_std.concept concept_SNOMED,
     rpt.leaf_scratch.conditions_map
WHERE concept_SNOMED.concept_code = SNOMED_concept_code
      AND concept_SNOMED.vocabulary_id = 'SNOMED'

-- Ensure that all EPIC EDG .1 → SNOMED are 1-to-1, so condition_concept_id can be unambiguously initialized
DECLARE @cardinality_Epic_2_SNOMED_mappings TABLE (Epic_concept_code NVARCHAR(50) PRIMARY KEY,
                                                   num_SNOMED_concept_codes INT)
INSERT INTO @cardinality_Epic_2_SNOMED_mappings
SELECT Epic_concept_code, COUNT(SNOMED_concept_code)
    FROM rpt.leaf_scratch.conditions_map
    GROUP BY Epic_concept_code
IF EXISTS (SELECT *
           FROM @cardinality_Epic_2_SNOMED_mappings
           WHERE 1 < num_SNOMED_concept_codes)
BEGIN
   DECLARE @msg VARCHAR = 'Some EPIC EDG .1 to SNOMED mappings are 1-to-many, so condition_concept_id ' +
                          'cannot be unambiguously initialized'
   RAISERROR(@msg, 16, 0)
END

-- Count the unique ICD10 codes in the conditions_map
DECLARE @num_ICD10_codes INT = (SELECT COUNT(DISTINCT ICD10_concept_code)
                                FROM rpt.leaf_scratch.conditions_map)
PRINT CAST(@num_ICD10_codes AS VARCHAR) + ' unique ICD10 codes found'

-- 5. Insert new mappings into rpt.Leaf_usagi.Leaf_staging, augmented with dependant attributes of each concept, and metadata
-- Unique keys in Leaf_staging prevent duplicate mappings from being inserted
USE rpt;

-- Assumption: Leaf_usagi.Leaf_staging contains no records WHERE mapping_creation_user = 'Arthur Goldberg''s conditions.sql script'
IF EXISTS (SELECT *
           FROM Leaf_usagi.Leaf_staging
           WHERE mapping_creation_user = 'Arthur Goldberg''s conditions.sql script')
BEGIN
   DECLARE @msg VARCHAR = 'Leaf_usagi.Leaf_staging contains records from this conditions.sql script'
   RAISERROR(@msg, 16, 0)
END

-- Insert new mappings into Leaf_staging
INSERT INTO Leaf_usagi.Leaf_staging(source_concept_id,
                                    source_concept_code,
                                    source_concept_name,
                                    source_concept_vocabulary_id,
                                    target_concept_id,
                                    target_concept_code,
                                    target_concept_name,
                                    target_concept_vocabulary_id,
                                    mapping_creation_user,
                                    mapping_creation_datetime)
SELECT Epic_concept_id,
       Epic_concept_code,
       Epic_concept_name,
       'EPIC EDG .1',
       SNOMED_concept_id,
       SNOMED_concept_code,
       SNOMED_concept_name,
       'SNOMED',
       'Arthur Goldberg''s conditions.sql script',
       GETDATE()
FROM leaf_scratch.conditions_map
WHERE -- Do not insert mappings that would duplicate manual mappings already in Leaf_usagi.mapping_import
      NOT sources LIKE '%MANUAL%'

DECLARE @num_mapping_import_records INT = (SELECT COUNT(*) FROM Leaf_usagi.Leaf_staging)
PRINT CAST(@num_mapping_import_records AS VARCHAR) + ' records in Leaf_usagi.Leaf_staging'

PRINT 'Finishing ''conditions.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT ''
