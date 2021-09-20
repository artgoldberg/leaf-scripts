/*
 * Create mappings from Epic's EDG diagnosis IDs to ICD-10-CM
 * Results are new entries in the Leaf_usagi.Leaf_staging table
 * Author: Arthur.Goldberg@mssm.edu
 */

/*
Must be executed as goldba06@MSSMCAMPUS.MSSM.EDU.

Steps
0. Analyze EDG <-> ICD-10 mappings
1. Map 'Epic diagnosis ID' to ICD-10-CM, from the Epic concept tables in src
1a. Create conditions_map_direct table
2. Review conditions_map_direct
3. Insert new mappings into rpt.Leaf_usagi.Leaf_staging
*/

-- TODOs
-- Do these EDG to ICD-10-CM mappings need to hand-reviewed?

-- TODO style improvements:
-- clean up comments
-- reduce code duplication


-- 0. Analyze EDG <-> ICD-10 mappings
-- Schema for table mapping diagnosis concept ids

PRINT 'Starting ''conditions_I10_to_EDG.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120)

USE src;

-- 0a. Analyze EDG <-> ICD-10 mappings
-- Get all EDG <-> ICD-10 mappings in Caboodle
DROP TABLE IF EXISTS #all_EDG_ICD10_mappings

CREATE TABLE #all_EDG_ICD10_mappings(
    Epic_concept_id INT NOT NULL,
    Epic_concept_code NVARCHAR(50) NOT NULL,
    Epic_concept_name NVARCHAR(255) NOT NULL,
    ICD10_concept_id INT NOT NULL,
    ICD10_concept_code NVARCHAR(50) NOT NULL,
    ICD10_concept_name NVARCHAR(255) NOT NULL
)

INSERT INTO #all_EDG_ICD10_mappings
SELECT EDG_concept.concept_id,
       DiagnosisDim.DiagnosisEpicId,
       DiagnosisDim.name,
       ICD10_concept.concept_id,
       DTD.Value,
       DTD.DisplayString
FROM caboodle.DiagnosisDim DiagnosisDim
    INNER JOIN caboodle.DiagnosisTerminologyDim DTD ON DiagnosisDim.DiagnosisKey = DTD.DiagnosisKey,
    omop.cdm.concept EDG_concept,
    omop.cdm.concept ICD10_concept
WHERE DTD.[Type] = 'ICD-10-CM'
    -- Avoid non-Clarity data added by Population Health
    AND DTD._HasSourceClarity = 1 AND DTD._IsDeleted = 0
    AND DiagnosisDim._HasSourceClarity = 1 AND DiagnosisDim._IsDeleted = 0
    -- Don't map to ICD-10-CM IMO0001, which codes for 'Reserved for inherently not codable concepts without codable children'
    -- or to IMO0002, 'Reserved for concepts with insufficient information to code with codable children'
    AND NOT DTD.Value IN('IMO0001', 'IMO0002')
    AND EDG_concept.vocabulary_id = 'EPIC EDG .1'
    AND EDG_concept.concept_code = DiagnosisDim.DiagnosisEpicId
    AND ICD10_concept.vocabulary_id = 'ICD10CM'
    AND ICD10_concept.concept_code = DTD.Value;

USE rpt;

-- Distributions of number of mappings in the EDG - ICD10 mapping
IF (NOT EXISTS (SELECT *
                FROM information_schema.tables
                WHERE table_schema = 'leaf_scratch'
                AND table_name = 'mapping_cardinality_distributions'))
    BEGIN
        CREATE TABLE leaf_scratch.mapping_cardinality_distributions
        (
            num_concepts INT NOT NULL,              -- number of concepts
            num_mappings INT NOT NULL,              -- number of mappings these concepts have
            vocabulary_id NVARCHAR(50) NOT NULL,
            mapping NVARCHAR(50) NOT NULL
        )
    END
ELSE
    DELETE FROM leaf_scratch.mapping_cardinality_distributions

-- Distributions EDG -> ICD10 mappings
-- First, obtain counts of mappings for each concept id
DROP TABLE IF EXISTS #counts_of_EDG_ICD10_mappings
CREATE TABLE #counts_of_EDG_ICD10_mappings(
    concept_id INT NOT NULL,
    num_mappings INT NOT NULL,
    vocabulary_id NVARCHAR(50) NOT NULL
)
-- Unique key on (concept_id, vocabulary_id)
ALTER TABLE #counts_of_EDG_ICD10_mappings
ADD CONSTRAINT PK_no_duped_concepts UNIQUE (concept_id,
                                            vocabulary_id)

INSERT INTO #counts_of_EDG_ICD10_mappings
SELECT Epic_concept_id,
       COUNT(Epic_concept_id) num_mappings,
       'EPIC EDG .1'
FROM #all_EDG_ICD10_mappings
GROUP BY Epic_concept_id

INSERT INTO #counts_of_EDG_ICD10_mappings
SELECT ICD10_concept_id,
       COUNT(ICD10_concept_id) num_mappings,
       'ICD10CM'
FROM #all_EDG_ICD10_mappings
GROUP BY ICD10_concept_id

INSERT INTO leaf_scratch.mapping_cardinality_distributions
SELECT COUNT(num_mappings),
       num_mappings,
       'EPIC EDG .1',
       'EPIC EDG .1 to ICD10CM'
FROM #counts_of_EDG_ICD10_mappings
WHERE vocabulary_id = 'EPIC EDG .1'
GROUP BY num_mappings

-- Distributions ICD10 -> EDG mappings
INSERT INTO leaf_scratch.mapping_cardinality_distributions
SELECT COUNT(num_mappings),
       num_mappings,
       'ICD10CM',
       'ICD10CM to EPIC EDG .1'
FROM #counts_of_EDG_ICD10_mappings
WHERE vocabulary_id = 'ICD10CM'
GROUP BY num_mappings

-- Count total number of mappings, and number of 1-to-1 mappings
DECLARE @num_EDG_I10_mappings INT = (SELECT COUNT(*)
                                     FROM #all_EDG_ICD10_mappings)

DECLARE @num_1_to_1_EDG_I10_mappings INT =
(SELECT COUNT(*)
 FROM #counts_of_EDG_ICD10_mappings counts_of_EDG_mappings,
      #counts_of_EDG_ICD10_mappings counts_of_ICD10_mappings,
      #all_EDG_ICD10_mappings all_EDG_ICD10_mappings
 WHERE counts_of_EDG_mappings.vocabulary_id = 'EPIC EDG .1'
       AND counts_of_EDG_mappings.num_mappings = 1
       AND counts_of_ICD10_mappings.vocabulary_id = 'ICD10CM'
       AND counts_of_ICD10_mappings.num_mappings = 1
       AND all_EDG_ICD10_mappings.Epic_concept_id = counts_of_EDG_mappings.concept_id
       AND all_EDG_ICD10_mappings.ICD10_concept_id = counts_of_ICD10_mappings.concept_id)

PRINT CAST(@num_1_to_1_EDG_I10_mappings AS VARCHAR) + ' of all ' + CAST(@num_EDG_I10_mappings AS VARCHAR) +
      ' EDG <-> ICD-10 mappings are 1-to-1 and onto, or ' +
      FORMAT(CAST(@num_1_to_1_EDG_I10_mappings AS FLOAT) / CAST(@num_EDG_I10_mappings AS FLOAT),
                                                                '##.0%', 'en-US');

-- 1. Map 'Epic diagnosis ID' to ICD-10-CM, from the Epic concept tables in src
-- 1a. Create conditions_map_direct table
USE rpt;

IF (NOT EXISTS (SELECT *
                FROM information_schema.tables
                WHERE table_schema = 'leaf_scratch'
                AND table_name = 'conditions_map_direct'))
    BEGIN
        CREATE TABLE leaf_scratch.conditions_map_direct
        (
            Epic_concept_id INT NOT NULL,
            Epic_concept_code NVARCHAR(50) NOT NULL,
            Epic_concept_name NVARCHAR(255) NOT NULL,
            ICD10_concept_id INT NOT NULL,
            ICD10_concept_code NVARCHAR(50),
            ICD10_concept_name NVARCHAR(255),
            -- Relationship of curated Epic -> ICD10 mapping to automated mapping
            -- TODO: use when available
            -- hand_map_status NVARCHAR(50),
            sources NVARCHAR(200) NOT NULL,     -- Sources for a record
            comment NVARCHAR(200)
        )
    END
ELSE
    DELETE FROM leaf_scratch.conditions_map_direct

-- Insert Epic EDG .1 to ICD10 mappings
INSERT INTO rpt.leaf_scratch.conditions_map_direct (Epic_concept_id,
                                                    Epic_concept_code,
                                                    Epic_concept_name,
                                                    ICD10_concept_id,
                                                    ICD10_concept_code,
                                                    ICD10_concept_name,
                                                    sources)
SELECT Epic_concept_id,
       Epic_concept_code,
       Epic_concept_name,
       ICD10_concept_id,
       ICD10_concept_code,
       ICD10_concept_name,
       'Caboodle'
FROM #all_EDG_ICD10_mappings


-- 2. Review conditions_map_direct

-- Count the unique ICD10 codes in the conditions_map_direct
DECLARE @num_ICD10_codes INT = (SELECT COUNT(DISTINCT ICD10_concept_code)
                                FROM rpt.leaf_scratch.conditions_map_direct)
PRINT CAST(@num_ICD10_codes AS VARCHAR) + ' unique ICD10 codes mapped to'

-- 3. Insert new mappings into rpt.Leaf_usagi.Leaf_staging, augmented with dependant attributes of each concept, and metadata
-- Unique keys in Leaf_staging prevent duplicate mappings from being inserted
USE rpt;

-- Ensure that Leaf_usagi.Leaf_staging contains no records inserted by this script previously
DELETE
FROM Leaf_usagi.Leaf_staging
WHERE mapping_creation_user = 'Arthur Goldberg''s conditions_I10_to_EDG.sql script'

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
       ICD10_concept_id,
       ICD10_concept_code,
       ICD10_concept_name,
       'ICD10CM',
       'Arthur Goldberg''s conditions_I10_to_EDG.sql script',
       GETDATE()
FROM leaf_scratch.conditions_map_direct
WHERE -- Do not insert mappings that would duplicate manual mappings already in Leaf_usagi.mapping_import
      NOT sources LIKE '%MANUAL%'

DECLARE @num_mapping_import_records INT = (SELECT COUNT(*)
                                           FROM Leaf_usagi.Leaf_staging
                                           WHERE mapping_creation_user = 'Arthur Goldberg''s conditions_I10_to_EDG.sql script')
PRINT CAST(@num_mapping_import_records AS VARCHAR) + ' records inserted into Leaf_usagi.Leaf_staging'

PRINT 'Finishing ''conditions_I10_to_EDG.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT ''
