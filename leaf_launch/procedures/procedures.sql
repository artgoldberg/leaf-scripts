/*
 * Create mappings from Epic's EAP and ORP procedure codes to CPT4
 * Results are new entries in the Leaf_usagi.Leaf_staging table
 * Author: Arthur.Goldberg@mssm.edu
 */

/*
Must be executed as goldba06@MSSMCAMPUS.MSSM.EDU.

Steps
1. Create procedures_map table
2. Map Epic's EAP and ORP procedure codes to CPT, from the Epic concepts in src.caboodle.ProcedureDim
3. Clean up rpt.leaf_scratch.curated_procedure_mappings
4. Integrate Sharon's existing manual mappings of Epic's EAP and ORP procedure codes to CPT, from leaf_scratch.curated_procedure_mappings
4a. If manual mapping is consistent, mark procedures_map.hand_map_status 'CONSISTENT'
4b. If manual mapping conflicts, mark procedures_map.hand_map_status 'CONFLICTED',
    use the manual value selected for CPT, and update sources
4c. If manual mapping is missing, mark procedures_map.hand_map_status 'MISSING',
    add Epic's EAP and ORP procedure codes and CPT values, and update sources
5. Validate the procedures_map
6. Insert new mappings into rpt.Leaf_usagi.Leaf_staging
*/

PRINT CONVERT(VARCHAR, GETDATE(), 120) + ': starting ''procedures.sql'''

USE rpt;

-- 1. Create procedures_map table

-- TODO: create temporary procedures_map table with fewer constraints
-- and then clean up data and transfer it to a fully-constrained table
IF (NOT EXISTS (SELECT *
                FROM information_schema.tables
                WHERE table_schema = 'leaf_scratch'
                AND table_name = 'procedures_map'))
    BEGIN
        CREATE TABLE leaf_scratch.procedures_map
        (
            Epic_concept_id INT NOT NULL PRIMARY KEY,
            Epic_concept_code NVARCHAR(50) NOT NULL,
            Epic_concept_name NVARCHAR(255) NOT NULL,
            CPT4_concept_id INT NOT NULL,
            CPT4_concept_code NVARCHAR(50) NOT NULL,
            CPT4_concept_name NVARCHAR(255) NOT NULL,
            -- Relationship of Sharon's hand-coded Epic -> CPT4 mapping to automated mapping
            hand_map_status NVARCHAR(50),
            sources NVARCHAR(200) NOT NULL,     -- Sources for a record
            comment NVARCHAR(200)
        )
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
*/

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

IF (NOT EXISTS(SELECT 1
                FROM #mappings_in_code_not_in_cpt_code))
    BEGIN
        PRINT 'Mappings that use CptCode in procedure_dim are a superset of those from Code, except ' +
              'for a few conflicts in #conflicting_proc_mappings'
    END
ELSE
    PRINT 'Examine #mappings_in_code_not_in_cpt_code, which contains mappings available exclusively ' +
          'in procedure_dim.Code'
    SELECT *
    FROM #mappings_in_code_not_in_cpt_code

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

-- Temporarily incorporate these 'EPIC ORP .1' codes into procedures_map
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


-- 3. Clean up curated procedure mappings in rpt.leaf_scratch.curated_procedure_mappings
-- Discard rows that do not have a match, those with equivalence = 'UNMATCHED'
DELETE FROM leaf_scratch.curated_procedure_mappings
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
FROM leaf_scratch.curated_procedure_mappings;

DELETE FROM leaf_scratch.curated_procedure_mappings;

ALTER TABLE leaf_scratch.curated_procedure_mappings
ALTER COLUMN source_code NVARCHAR(50) NOT NULL;

ALTER TABLE leaf_scratch.curated_procedure_mappings
ALTER COLUMN source_frequency INT NOT NULL;

ALTER TABLE leaf_scratch.curated_procedure_mappings
ALTER COLUMN match_score FLOAT NOT NULL;

ALTER TABLE leaf_scratch.curated_procedure_mappings
ALTER COLUMN concept_id INT NOT NULL;

INSERT INTO leaf_scratch.curated_procedure_mappings
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
       created_on
FROM #temp_curated_procedure_mappings;
-- TODO: other possible clean-up of leaf_scratch.curated_procedure_mappings
-- Remove quotes around strings (which contain comma) -- perhaps just get name from concept, & check that it matches
-- Convert created_on & status_set_on to datetimes

/*
-- TODO: Do steps 4 - 6
-- TODO: After they've been annotated, re-load contents of #proc_mappings_from_SurgicalProcedureEpicId
-- with annotations that identify good mappings and stop incorporating them above

-- TODO: have Tim review this code
-- TODO: use stored procedures to reduce code duplication
*/

PRINT CONVERT(VARCHAR, GETDATE(), 120) + ': finishing ''procedures.sql'''
