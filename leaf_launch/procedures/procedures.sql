/*
 * Create mappings from Epic EAP and ORP procedure codes to CPT4
 * Results are entries in the Leaf_usagi.Leaf_staging table with
 * mapping_creation_user = 'Arthur Goldberg's procedures.sql script'
 * Author: Arthur.Goldberg@mssm.edu
 */

/*
Must be executed by a user that has UPDATE access to rpt, and SELECT access to omop and src.

Steps
1. Create procedures_map table
2. Map Epic's EAP and ORP procedure codes to CPT, from the Epic concepts in src.caboodle.ProcedureDim
3. Clean up rpt.leaf_procedures.curated_procedure_mappings
4. Integrate Sharon's existing manual mappings of Epic's EAP and ORP procedure codes to CPT, from leaf_procedures.curated_procedure_mappings
4a. If manual mapping is consistent, mark procedures_map.hand_map_status 'CONSISTENT'
4b. If manual mapping conflicts, mark procedures_map.hand_map_status 'CONFLICTED',
    use the manual value selected for CPT, and update sources
4c. If manual mapping is missing, mark procedures_map.hand_map_status 'MISSING',
    add Epic's EAP or ORP procedure codes and CPT values, and update sources
5. Validate procedures_map
6. Insert new mappings into rpt.Leaf_usagi.Leaf_staging
*/

PRINT CONVERT(VARCHAR, GETDATE(), 120) + ': starting ''procedures.sql'''

USE rpt;

-- 1. Create procedures_map table
IF (NOT EXISTS (SELECT *
                FROM information_schema.tables
                WHERE table_schema = 'leaf_scratch'
                AND table_name = 'procedures_map'))
    BEGIN
        CREATE TABLE leaf_scratch.procedures_map
        (
            Epic_concept_id INT NOT NULL,
            -- Caution: Epic_concept_code values may not be UNIQUE, as they're EAP OR ORP procedure codes
            Epic_concept_code NVARCHAR(50) NOT NULL,
            Epic_concept_name NVARCHAR(255) NOT NULL,
            CPT4_concept_id INT NOT NULL,
            CPT4_concept_code NVARCHAR(50),
            CPT4_concept_name NVARCHAR(255),
            -- Relationship of Sharon's curated Epic -> CPT4 mapping to automated mapping
            -- 'CONSISTENT' <=> a curated mapping is consistent with an automated mapping
            -- 'CONFLICTED' <=> a curated mapping conflicts with an automated mapping; the curated one takes precedence
            -- 'MISSING' <=> the source code of a curated mapping isn't used by any automated mapping; the curated one is used
            hand_map_status NVARCHAR(50),
            sources NVARCHAR(200) NOT NULL,     -- Sources for a record
            comment NVARCHAR(200)
        )

        ALTER TABLE leaf_scratch.procedures_map
        ADD CONSTRAINT UNIQUE_concept_id_mappings UNIQUE (Epic_concept_id,
                                                          CPT4_concept_id)
    END
ELSE
    TRUNCATE TABLE leaf_scratch.procedures_map

-- 2. Map Epic's EAP and ORP procedure codes to CPT, from the Epic concepts in src.caboodle.ProcedureDim
USE src;

DROP TABLE IF EXISTS #proc_mappings_from_code;
DROP TABLE IF EXISTS #proc_mappings_from_cpt_code;

-- Get mappings from the Code field
SELECT procedure_dim.ProcedureEpicId,
       procedure_dim.[Name] AS 'Epic_name',
       CPT4_concept.concept_name,
       procedure_dim.Code AS 'Code'
INTO #proc_mappings_from_code
FROM caboodle.ProcedureDim procedure_dim,
     omop.cdm.concept Epic_concept,
     omop.cdm.concept CPT4_concept
WHERE procedure_dim.IsCurrent = 1
      AND procedure_dim.Code != '*Unspecified'
      AND procedure_dim.ProcedureEpicId IS NOT NULL
      AND procedure_dim.CodeSet = 'CPT(R)'
      -- These appear to be invalid, deleted or non-procedure codes
      AND NOT (procedure_dim.[Name] LIKE '-----%'
               OR procedure_dim.[Name] LIKE 'CODE DELETED FOR %'
               OR procedure_dim.[Name] LIKE 'DELETED %'
               OR procedure_dim.[Name] LIKE 'COPAYMENT % DOLLARS')
      -- Avoid non-Clarity data added by Population Health
      AND procedure_dim._HasSourceClarity = 1 AND procedure_dim._IsDeleted = 0
      -- Ensure procedure_dim.Code is a valid CPT4 code
      AND CPT4_concept.vocabulary_id = 'CPT4'
      AND CPT4_concept.concept_code = procedure_dim.Code
      -- Ensure procedure_dim.ProcedureEpicId is a valid Epic 'EPIC EAP .1' code
      AND Epic_concept.vocabulary_id = 'EPIC EAP .1'
      -- The code for the Epic concept is a decimal in ProcedureEpicId
      AND Epic_concept.concept_code = CAST(procedure_dim.ProcedureEpicId AS NVARCHAR(50));

-- Get mappings directly from the CptCode field
SELECT procedure_dim.ProcedureEpicId,
       procedure_dim.[Name] AS 'Epic_name',
       CPT4_concept.concept_name,
       procedure_dim.CptCode AS 'Code'
INTO #proc_mappings_from_cpt_code
FROM caboodle.ProcedureDim procedure_dim,
     omop.cdm.concept Epic_concept,
     omop.cdm.concept CPT4_concept
WHERE procedure_dim.IsCurrent = 1
      AND procedure_dim.ProcedureEpicId IS NOT NULL
      AND procedure_dim.CptCode IS NOT NULL
      AND NOT procedure_dim.CptCode IN ('', '*Not Applicable', '*Deleted', '*Unknown')
      -- These appear to be invalid, deleted or non-procedure codes
      AND NOT (procedure_dim.[Name] LIKE '-----%'
               OR procedure_dim.[Name] LIKE 'CODE DELETED FOR %'
               OR procedure_dim.[Name] LIKE 'DELETED %'
               OR procedure_dim.[Name] LIKE 'COPAYMENT % DOLLARS')
      -- Avoid non-Clarity data added by Population Health
      AND procedure_dim._HasSourceClarity = 1 AND procedure_dim._IsDeleted = 0
      -- Ensure procedure_dim.Code is a valid CPT4 code
      AND CPT4_concept.vocabulary_id = 'CPT4'
      AND CPT4_concept.concept_code = procedure_dim.CptCode
      -- Ensure procedure_dim.ProcedureEpicId is a valid Epic 'EPIC EAP .1' code
      AND Epic_concept.vocabulary_id = 'EPIC EAP .1'
      -- The code for the Epic concept is a decimal in ProcedureEpicId
      AND Epic_concept.concept_code = CAST(procedure_dim.ProcedureEpicId AS NVARCHAR(50));

-- Conflicting codes from the two methods, which can be reconciled or ignored
-- Join on ProcedureEpicId, showing both Code and CptCode
DROP TABLE IF EXISTS #conflicting_proc_mappings;

SELECT #proc_mappings_from_cpt_code.ProcedureEpicId,
       #proc_mappings_from_cpt_code.Epic_name,
       #proc_mappings_from_cpt_code.Code AS 'CptCode_code',
       #proc_mappings_from_code.Code AS 'Code_code'
INTO #conflicting_proc_mappings
FROM #proc_mappings_from_cpt_code,
     #proc_mappings_from_code
WHERE #proc_mappings_from_cpt_code.ProcedureEpicId = #proc_mappings_from_code.ProcedureEpicId
      AND #proc_mappings_from_cpt_code.Code <> #proc_mappings_from_code.Code;

/*
Data review:
We're using caboodle.ProcedureDim to map Epic procedure codes into CPT4 codes.
Both the Code and CptCode fields can contain CPT4 codes. Examining them, I find that
mappings that use CptCode in procedure_dim are a superset of those from Code, except for these
3 codes in #conflicting_proc_mappings:

ProcedureEpicId Epic_name CptCode_code Code_code
5725	MAMMOGRAPHY DIAGNOSTIC BILATERAL	77066	77056
151522	UTERINE FIBROID EMBOLIZATION	37243	37210
44805	DEXA BONE DENSITY, VERTEBRAL FRACTURE ASSESSMENT	77086	77082

We ignore these mappings, which look they might be typos.
*/

DROP TABLE IF EXISTS #mappings_in_code_not_in_cpt_code;

SELECT *
INTO #mappings_in_code_not_in_cpt_code
FROM (SELECT *
      FROM #proc_mappings_from_code

      EXCEPT

      SELECT *
      FROM #proc_mappings_from_cpt_code) code_except_cpt_code
WHERE code_except_cpt_code.ProcedureEpicId NOT IN (SELECT ProcedureEpicId
                                                   FROM #conflicting_proc_mappings)

DECLARE @max_num_conflicting_mappings INT = 5
IF (NOT EXISTS(SELECT 1
                FROM #mappings_in_code_not_in_cpt_code)
    AND @max_num_conflicting_mappings >=
        (SELECT COUNT(*)
         FROM #conflicting_proc_mappings))
    BEGIN
        PRINT 'Mappings that use CptCode in procedure_dim are a superset of those from Code, except for at most ' +
              CONVERT(VARCHAR, @max_num_conflicting_mappings) + ' conflicts in #conflicting_proc_mappings.'
    END
ELSE
    BEGIN
        PRINT 'WARNING: Examine #mappings_in_code_not_in_cpt_code, which contains more than ' +
               CONVERT(VARCHAR, @max_num_conflicting_mappings) +
               ' mappings available exclusively in procedure_dim.Code.'
        SELECT *
        FROM #mappings_in_code_not_in_cpt_code
    END

USE rpt;

-- Keep mappings obtained using CptCode, except the conflicting ones
INSERT INTO leaf_scratch.procedures_map (Epic_concept_id,
                                         Epic_concept_code,
                                         Epic_concept_name,
                                         CPT4_concept_id,
                                         CPT4_concept_code,
                                         CPT4_concept_name,
                                         sources)
SELECT Epic_concept.concept_id,
       Epic_concept.concept_code,
       Epic_concept.concept_name,
       CPT4_concept.concept_id,
       CPT4_concept.concept_code,
       CPT4_concept.concept_name,
       'caboodle.ProcedureDim via procedures.sql'
FROM #proc_mappings_from_cpt_code,
     omop.cdm.concept Epic_concept,
     omop.cdm.concept CPT4_concept
WHERE ProcedureEpicId NOT IN (SELECT ProcedureEpicId
                              FROM #conflicting_proc_mappings)
      AND Epic_concept.concept_code = CAST(ProcedureEpicId AS NVARCHAR(50))
      AND Epic_concept.vocabulary_id = 'EPIC EAP .1'
      AND CPT4_concept.concept_code = Code
      AND CPT4_concept.vocabulary_id = 'CPT4';


-- Map 'EPIC ORP .1' codes
-- Leverage Sharon's observation: the SurgicalProcedureEpicId values that do not start with 'M'
-- almost always contain the CPT code embedded in the 4th through 8th position.
DROP TABLE IF EXISTS #proc_mappings_from_SurgicalProcedureEpicId;

SELECT procedure_dim.SurgicalProcedureEpicId,
       SUBSTRING(procedure_dim.SurgicalProcedureEpicId, 4, 5) AS 'CPT4 Code',
       procedure_dim.[Name] AS 'Epic name',
       CPT4_concept.concept_name AS 'CPT4 name'
INTO #proc_mappings_from_SurgicalProcedureEpicId
FROM src.caboodle.ProcedureDim procedure_dim,
     omop.cdm.concept CPT4_concept
WHERE NOT procedure_dim.SurgicalProcedureEpicId LIKE 'M%'
      AND procedure_dim.SurgicalProcedureEpicId NOT IN ('*Not Applicable', '*Unknown')
      -- Skip SurgicalProcedureEpicIds that are too short
      AND 8 <= LEN(procedure_dim.SurgicalProcedureEpicId)
      AND procedure_dim.IsCurrent = 1
      -- Avoid non-Clarity data added by Population Health
      AND procedure_dim._HasSourceClarity = 1 AND procedure_dim._IsDeleted = 0
      AND CPT4_concept.vocabulary_id = 'CPT4'
      AND CPT4_concept.concept_code = SUBSTRING(procedure_dim.SurgicalProcedureEpicId, 4, 5);

-- Incorporate these 'EPIC ORP .1' codes into procedures_map
INSERT INTO leaf_scratch.procedures_map (Epic_concept_id,
                                         Epic_concept_code,
                                         Epic_concept_name,
                                         CPT4_concept_id,
                                         CPT4_concept_code,
                                         CPT4_concept_name,
                                         sources)
SELECT Epic_concept.concept_id,
       Epic_concept.concept_code,
       Epic_concept.concept_name,
       CPT4_concept.concept_id,
       CPT4_concept.concept_code,
       CPT4_concept.concept_name,
       'caboodle.ProcedureDim via procedures.sql'
FROM #proc_mappings_from_SurgicalProcedureEpicId,
     omop.cdm.concept Epic_concept,
     omop.cdm.concept CPT4_concept
WHERE Epic_concept.concept_code = CAST(SurgicalProcedureEpicId AS NVARCHAR(50))
      AND Epic_concept.vocabulary_id = 'EPIC ORP .1'
      AND CPT4_concept.concept_code = [CPT4 Code]
      AND CPT4_concept.vocabulary_id = 'CPT4';


-- 3. Clean up curated procedure mappings in rpt.leaf_procedures.curated_procedure_mappings,
-- which were loaded by procedures.sh.
-- Discard rows that do not have a match, those with equivalence = 'UNMATCHED'
DELETE FROM leaf_procedures.curated_procedure_mappings
WHERE equivalence = 'UNMATCHED';

-- Convert types of fields in curated_procedure_mappings as needed
-- Initially, all fields are VARCHAR(255)
-- Conversions:
-- source_code: -> NVARCHAR(50), matching cdm.concept.concept_code
-- source_frequency: -> INT
-- match_score: -> FLOAT
-- concept_id: -> INT, matching cdm.concept.concept_id

-- Copy curated_procedure_mappings to a temp table, and copy back converted types
DROP TABLE IF EXISTS #temp_curated_procedure_mappings;

SELECT *
INTO #temp_curated_procedure_mappings
FROM leaf_procedures.curated_procedure_mappings;

DELETE FROM leaf_procedures.curated_procedure_mappings;

ALTER TABLE leaf_procedures.curated_procedure_mappings
ALTER COLUMN source_code NVARCHAR(50) NOT NULL;

ALTER TABLE leaf_procedures.curated_procedure_mappings
ALTER COLUMN source_frequency INT NOT NULL;

ALTER TABLE leaf_procedures.curated_procedure_mappings
ALTER COLUMN match_score FLOAT NOT NULL;

ALTER TABLE leaf_procedures.curated_procedure_mappings
ALTER COLUMN concept_id INT NOT NULL;

ALTER TABLE leaf_procedures.curated_procedure_mappings
ADD source_concept_vocab NVARCHAR(100);

ALTER TABLE leaf_procedures.curated_procedure_mappings
ADD target_concept_vocabulary NVARCHAR(100);

INSERT INTO leaf_procedures.curated_procedure_mappings
SELECT source_code_type,
       CONVERT(NVARCHAR(50), source_code),
       source_name,
       CONVERT(INT, source_frequency),
       source_auto_assigned_concept_ids,
       code_set,
       code,
       CONVERT(FLOAT, match_score),
       mapping_status,
       equivalence,
       status_set_by,
       status_set_on,
       CONVERT(INT, concept_id),
       concept_name,
       domain_id,
       mapping_type,
       comment,
       created_by,
       created_on,
       NULL,
       NULL
FROM #temp_curated_procedure_mappings;

-- Must start new batch so stupid SQL Server complier understands source_concept_vocab column below
GO

-- TODO: other possible clean-up of leaf_procedures.curated_procedure_mappings
-- Remove quotes around strings (which contain comma) -- perhaps just get name from concept, & check that it matches
-- Convert created_on & status_set_on to datetimes

-- 4. Integrate the curated mappings of Epic's EAP and ORP procedure codes to CPT

-- 4 alpha. Check the curated mappings
-- Which surgical mappings are in concept with vocabulary_id = 'EPIC ORP .1'?
UPDATE leaf_procedures.curated_procedure_mappings
SET source_concept_vocab = 'EPIC ORP .1'
FROM omop.cdm.concept AS concept
WHERE source_code_type = 'surgical'
      AND concept.vocabulary_id = 'EPIC ORP .1'
      AND concept.concept_code = source_code;

-- Which non-surgical mappings are in concept with vocabulary_id = 'EPIC EAP .1'?
UPDATE leaf_procedures.curated_procedure_mappings
SET source_concept_vocab = 'EPIC EAP .1'
FROM omop.cdm.concept AS concept
WHERE source_code_type = 'non-surgical'
      AND concept.vocabulary_id = 'EPIC EAP .1'
      AND concept.concept_code = source_code;

-- Ensure that all source concept vocabulary_ids are either 'EPIC ORP .1' or 'EPIC EAP .1'
IF (EXISTS(SELECT 1
           FROM leaf_procedures.curated_procedure_mappings
           WHERE source_concept_vocab NOT IN ('EPIC ORP .1', 'EPIC EAP .1')))
    BEGIN
        DECLARE @msg NVARCHAR(MAX) = 'Error: leaf_procedures.curated_procedure_mappings contains mappings from ' +
                                      ' source concepts whose vocabulary ids are not ''EPIC ORP .1'' or ''EPIC EAP .1'''
        RAISERROR(@msg, 16, 0)
    END

-- Check on vocabulary_ids of target concept_ids
UPDATE curated_procedure_mappings
SET target_concept_vocabulary = concept.vocabulary_id
FROM leaf_procedures.curated_procedure_mappings AS curated_procedure_mappings,
     omop.cdm.concept AS concept
WHERE curated_procedure_mappings.concept_id = concept.concept_id

-- Unfortunately, 33 of the curated mappings map to SNOMED or HCPCS, not CPT4; delete and ignore these
DELETE leaf_procedures.curated_procedure_mappings
WHERE concept_id IN
    (SELECT curated_procedure_mappings.concept_id
     FROM leaf_procedures.curated_procedure_mappings AS curated_procedure_mappings,
          omop.cdm.concept AS concept
     WHERE curated_procedure_mappings.concept_id = concept.concept_id
           AND concept.vocabulary_id <> 'CPT4')

-- 4a. If manual mapping is consistent, mark procedures_map.hand_map_status 'CONSISTENT'
UPDATE leaf_scratch.procedures_map
SET hand_map_status = 'CONSISTENT',
    sources = 'Caboodle and MANUAL'
FROM leaf_scratch.procedures_map procedures_map,
     leaf_procedures.curated_procedure_mappings curated_procedure_mappings
WHERE procedures_map.Epic_concept_code = curated_procedure_mappings.source_code
      AND procedures_map.CPT4_concept_id = curated_procedure_mappings.concept_id

-- 4b. If manual mapping conflicts, mark procedures_map.hand_map_status 'CONFLICTED',
--     use the manual value selected for CPT, and update sources
UPDATE leaf_scratch.procedures_map
SET hand_map_status = 'CONFLICTED',
    CPT4_concept_id = curated_procedure_mappings.concept_id,
    sources = 'MANUAL'
FROM leaf_scratch.procedures_map procedures_map,
     leaf_procedures.curated_procedure_mappings curated_procedure_mappings
WHERE procedures_map.Epic_concept_code = curated_procedure_mappings.source_code
      AND NOT procedures_map.CPT4_concept_id = curated_procedure_mappings.concept_id

-- 4c. If manual mapping is missing, mark procedures_map.hand_map_status 'MISSING',
--     add Epic's EAP or ORP procedure codes and CPT values, and update sources
INSERT INTO leaf_scratch.procedures_map(Epic_concept_id,
                                        Epic_concept_code,
                                        Epic_concept_name,
                                        CPT4_concept_id,
                                        hand_map_status,
                                        sources)
SELECT EAP_or_ORP_concept.concept_id,
       EAP_or_ORP_concept.concept_code,
       EAP_or_ORP_concept.concept_name,
       curated_procedure_mappings.concept_id,
       'MISSING',
       'MANUAL'
FROM leaf_procedures.curated_procedure_mappings curated_procedure_mappings,
     omop.cdm.concept EAP_or_ORP_concept
WHERE curated_procedure_mappings.source_code = EAP_or_ORP_concept.concept_code
      AND curated_procedure_mappings.source_concept_vocab = EAP_or_ORP_concept.vocabulary_id
      AND NOT EXISTS(SELECT 1
                     FROM leaf_scratch.procedures_map inner_procedures_map
                     WHERE EAP_or_ORP_concept.concept_id = inner_procedures_map.Epic_concept_id)

-- 4c. continued; to ensure that all codes and names are consistent with the concept table
--     update CPT4_concept_code and CPT4_concept_name as a function of CPT4_concept_id
UPDATE leaf_scratch.procedures_map
SET CPT4_concept_code = CPT4_concept.concept_code,
    CPT4_concept_name = CPT4_concept.concept_name
FROM leaf_scratch.procedures_map procedures_map,
     omop.cdm.concept CPT4_concept
WHERE procedures_map.CPT4_concept_id = CPT4_concept.concept_id

-- Print counts of the hand_map_status values
SELECT hand_map_status, COUNT(hand_map_status)
FROM leaf_scratch.procedures_map
GROUP BY hand_map_status;

/*
-- TODO: additional constraints
The Epic_concept_id concept vocabulary_id is IN ('EPIC ORP .1', 'EPIC EAP .1')
Epic_concept_code and Epic_concept_name are consistent with the concept entry Epic_concept_id points to
The CPT4_concept_id concept vocabulary_id is 'CPT4'
CPT4_concept_code and CPT4_concept_name are consistent with the concept entry CPT4_concept_id points to
*/

-- Need to copy omop.cdm.concept because it lacks a PRIMARY KEY constraint on concept_id; why?
DROP TABLE IF EXISTS leaf_procedures.omop_concept

SELECT *
INTO leaf_procedures.omop_concept
FROM omop.cdm.concept;

ALTER TABLE leaf_procedures.omop_concept
ADD PRIMARY KEY (concept_id);

-- TODO: make this stable: have DROP CONSTRAINT operations execute independent of prior error
-- Constraints on leaf_scratch.procedures_map
-- Constraint: 2,000,000,000 <= Epic_concept_id
ALTER TABLE leaf_scratch.procedures_map
ADD CONSTRAINT CHK_Epic_concept_id CHECK (2000000000 <= Epic_concept_id);

-- Constraint: Epic_concept_id is an FK to a concept
ALTER TABLE leaf_scratch.procedures_map
ADD CONSTRAINT FK_Epic_concept_id
FOREIGN KEY (Epic_concept_id) REFERENCES leaf_procedures.omop_concept(concept_id);

-- Constraint: CPT4_concept_id < 2,000,000,000
ALTER TABLE leaf_scratch.procedures_map
ADD CONSTRAINT CHK_CPT4_concept_id CHECK (CPT4_concept_id < 2000000000);

-- Constraint: CPT4_concept_id is an FK to a concept
ALTER TABLE leaf_scratch.procedures_map
ADD CONSTRAINT FK_CPT4_concept_id
FOREIGN KEY (CPT4_concept_id) REFERENCES leaf_procedures.omop_concept(concept_id);

-- Drop these constraints on leaf_scratch.procedures_map
ALTER TABLE leaf_scratch.procedures_map
DROP CONSTRAINT IF EXISTS CHK_Epic_concept_id

ALTER TABLE leaf_scratch.procedures_map
DROP CONSTRAINT IF EXISTS FK_Epic_concept_id

ALTER TABLE leaf_scratch.procedures_map
DROP CONSTRAINT IF EXISTS CHK_CPT4_concept_id

ALTER TABLE leaf_scratch.procedures_map
DROP CONSTRAINT IF EXISTS FK_CPT4_concept_id

-- 6. Insert new procedures.sql mappings into rpt.Leaf_usagi.Leaf_staging
DELETE FROM Leaf_usagi.Leaf_staging
WHERE mapping_creation_user = 'Arthur Goldberg''s procedures.sql script'

-- Insert new Epic to CPT4 procedure mappings into Leaf_staging
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
       Epic_concept.vocabulary_id,
       CPT4_concept_id,
       CPT4_concept_code,
       CPT4_concept_name,
       'CPT4',
       'Arthur Goldberg''s procedures.sql script',
       GETDATE()
FROM leaf_scratch.procedures_map procedures_map,
     omop.cdm.concept Epic_concept
WHERE procedures_map.Epic_concept_id = Epic_concept.concept_id

/*
-- TODO: After they've been annotated, re-load contents of #proc_mappings_from_SurgicalProcedureEpicId
-- with annotations that identify good mappings and stop incorporating them above

-- TODO: have Tim review this code
-- TODO: use stored procedures to reduce code duplication between this and conditions.sql
*/
DECLARE @num_mapping_import_records INT = (SELECT COUNT(*)
                                           FROM Leaf_usagi.Leaf_staging
                                           WHERE mapping_creation_user = 'Arthur Goldberg''s procedures.sql script')
PRINT CAST(@num_mapping_import_records AS VARCHAR) + ' procedure mapping records in Leaf_usagi.Leaf_staging'

PRINT CONVERT(VARCHAR, GETDATE(), 120) + ': finishing ''procedures.sql'''
PRINT ''
