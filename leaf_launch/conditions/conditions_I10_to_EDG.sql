/*
 * Create mappings from Epic's EDG diagnosis IDs to ICD-10-CM
 * Results are new entries in the Leaf_usagi.Leaf_staging table
 * Author: Arthur.Goldberg@mssm.edu
 */

/*
Must be executed as goldba06@MSSMCAMPUS.MSSM.EDU.

Steps
0. Create conditions_map_direct table
1. Map 'Epic diagnosis ID' to ICD-10-CM, from the Epic concept tables in src
1a. Ignore EDG codes that do not map 1-to-1 to ICD-10
2. TODO: Question: what should be done with Sharon's curated mappings of EDG to SNOMED?
3. Validate the conditions_map_direct
4. Insert new mappings into rpt.Leaf_usagi.Leaf_staging
*/

-- TODOs
-- Use cdm instead of cdm_phi_std

-- TODO style improvements:
-- clean up comments
-- reduce code duplication


-- 0. Create conditions_map_direct table
-- Schema for table mapping diagnosis concept ids

PRINT 'Starting ''conditions_I10_to_EDG.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120)

USE rpt;

IF (NOT EXISTS (SELECT *
                FROM information_schema.tables
                WHERE table_schema = 'leaf_scratch'
                AND table_name = 'conditions_map_direct'))
    BEGIN
        CREATE TABLE leaf_scratch.conditions_map_direct
        (
            Epic_concept_id INT NOT NULL UNIQUE,
            Epic_concept_code NVARCHAR(50) NOT NULL PRIMARY KEY,
            Epic_concept_name NVARCHAR(255) NOT NULL,
            ICD10_concept_id INT NOT NULL,
            ICD10_concept_code NVARCHAR(50),
            ICD10_concept_name NVARCHAR(255),
            -- Relationship of Sharon's hand-coded Epic -> SNOMED mapping to automated mapping
            hand_map_status NVARCHAR(50),
            sources NVARCHAR(200) NOT NULL,     -- Sources for a record
            comment NVARCHAR(200)
        )
    END
ELSE
    DELETE FROM leaf_scratch.conditions_map_direct


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

SELECT *
FROM @cardinality_epic_to_icd10
WHERE 1 < [@cardinality_epic_to_icd10].num_ICD10_concept_codes

DECLARE @num_1_to_many_mappings INT = (SELECT COUNT(*)
                                       FROM @cardinality_epic_to_icd10
                                       WHERE 1 < [@cardinality_epic_to_icd10].num_ICD10_concept_codes)
PRINT 'Ignoring ' + CAST(@num_1_to_many_mappings AS VARCHAR) +
      ' Epic diagnosis codes that map 1-to-many to ICD10 in Epic'

-- Insert Epic diagnosis codes that map 1-to-1 to ICD10
INSERT INTO rpt.leaf_scratch.conditions_map_direct (Epic_concept_code,
                                                    Epic_concept_name,
                                                    ICD10_concept_id,
                                                    ICD10_concept_code,
                                                    ICD10_concept_name,
                                                    sources)
SELECT DiagnosisDim.DiagnosisEpicId,
       DiagnosisDim.name,
       concept_ICD10.concept_id,
       DTD.Value,
       DTD.DisplayString,
       'Caboodle'
FROM src.caboodle.DiagnosisDim DiagnosisDim
    INNER JOIN caboodle.DiagnosisTerminologyDim DTD ON DiagnosisDim.DiagnosisKey = DTD.DiagnosisKey,
    omop.cdm_phi_std.concept concept_ICD10
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
    AND NOT DTD.Value IN('IMO0001', 'IMO0002')
    AND concept_ICD10.concept_code = DTD.Value
    ;

-- 3. Validate the conditions_map_direct
-- Ensure that there are no NULLs values for ICD10 or SNOMED codes, so all EPIC codes can be fully mapped
DECLARE @num_icd10_nulls INT = (SELECT COUNT(*)
                                FROM rpt.leaf_scratch.conditions_map_direct
                                WHERE ICD10_concept_code IS NULL)
PRINT 'Deleting ' + CAST(@num_icd10_nulls AS VARCHAR) + ' records that lack an ICD-10-CM code'

DELETE
FROM rpt.leaf_scratch.conditions_map_direct
WHERE ICD10_concept_code IS NULL

-- Count and then remove records containing SNOMED codes that do not contain a mapping to ICD-10-CM in CONCEPT_RELATIONSHIP
DECLARE @num_snomed_nulls INT = (SELECT COUNT(*)
                                 FROM rpt.leaf_scratch.conditions_map_direct
                                 WHERE SNOMED_concept_code IS NULL)
PRINT 'Deleting ' + CAST(@num_snomed_nulls AS VARCHAR) + ' records that lack a SNOMED code'

DELETE
FROM rpt.leaf_scratch.conditions_map_direct
WHERE SNOMED_concept_code IS NULL;

-- Enrich conditions_map_direct with concept ids
UPDATE rpt.leaf_scratch.conditions_map_direct
SET Epic_concept_id = concept_Epic.concept_id
FROM omop.cdm_phi_std.concept concept_Epic,
     rpt.leaf_scratch.conditions_map_direct
WHERE concept_Epic.concept_code = Epic_concept_code
      AND concept_Epic.vocabulary_id = 'EPIC EDG .1'

UPDATE rpt.leaf_scratch.conditions_map_direct
SET SNOMED_concept_id = concept_SNOMED.concept_id
FROM omop.cdm_phi_std.concept concept_SNOMED,
     rpt.leaf_scratch.conditions_map_direct
WHERE concept_SNOMED.concept_code = SNOMED_concept_code
      AND concept_SNOMED.vocabulary_id = 'SNOMED'

-- Ensure that all EPIC EDG .1 → SNOMED are 1-to-1, so condition_concept_id can be unambiguously initialized
DECLARE @cardinality_Epic_2_SNOMED_mappings TABLE (Epic_concept_code NVARCHAR(50) PRIMARY KEY,
                                                   num_SNOMED_concept_codes INT)
INSERT INTO @cardinality_Epic_2_SNOMED_mappings
SELECT Epic_concept_code, COUNT(SNOMED_concept_code)
    FROM rpt.leaf_scratch.conditions_map_direct
    GROUP BY Epic_concept_code
IF EXISTS (SELECT *
           FROM @cardinality_Epic_2_SNOMED_mappings
           WHERE 1 < num_SNOMED_concept_codes)
BEGIN
   DECLARE @msg VARCHAR = 'Some EPIC EDG .1 to SNOMED mappings are 1-to-many, so condition_concept_id ' +
                          'cannot be unambiguously initialized'
   RAISERROR(@msg, 16, 0)
END

-- Count the unique ICD10 codes in the conditions_map_direct
DECLARE @num_ICD10_codes INT = (SELECT COUNT(DISTINCT ICD10_concept_code)
                                FROM rpt.leaf_scratch.conditions_map_direct)
PRINT CAST(@num_ICD10_codes AS VARCHAR) + ' unique ICD10 codes found'

-- 5. Insert new mappings into rpt.Leaf_usagi.Leaf_staging, augmented with dependant attributes of each concept, and metadata
-- Unique keys in Leaf_staging prevent duplicate mappings from being inserted
USE rpt;

-- Assumption: Leaf_usagi.Leaf_staging contains no records WHERE mapping_creation_user = 'Arthur Goldberg''s conditions_I10_to_EDG.sql script'
IF EXISTS (SELECT *
           FROM Leaf_usagi.Leaf_staging
           WHERE mapping_creation_user = 'Arthur Goldberg''s conditions_I10_to_EDG.sql script')
BEGIN
   DECLARE @msg VARCHAR = 'Leaf_usagi.Leaf_staging contains records from this conditions_I10_to_EDG.sql script'
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
       'Arthur Goldberg''s conditions_I10_to_EDG.sql script',
       GETDATE()
FROM leaf_scratch.conditions_map_direct
WHERE -- Do not insert mappings that would duplicate manual mappings already in Leaf_usagi.mapping_import
      NOT sources LIKE '%MANUAL%'

DECLARE @num_mapping_import_records INT = (SELECT COUNT(*) FROM Leaf_usagi.Leaf_staging)
PRINT CAST(@num_mapping_import_records AS VARCHAR) + ' records in Leaf_usagi.Leaf_staging'

PRINT 'Finishing ''conditions_I10_to_EDG.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT ''
