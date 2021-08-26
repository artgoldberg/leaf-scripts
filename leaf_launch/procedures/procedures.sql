/*
 * Create mappings from 'Epic procedure codes' to CPT
 * Results are new entries in the Leaf_usagi.Leaf_staging table
 * Author: Arthur.Goldberg@mssm.edu
 */

/*
Must be executed as goldba06@MSNYUHEALTH.ORG.

Steps
0. Create procedures_map table
1. Map 'Epic procedure codes' to CPT, from the Epic concept table src.caboodle.ProcedureDim 
2. Integrate Sharon's existing manual mappings of 'Epic procedure codes' to CPT, from rpt.Leaf_usagi.mapping_import
2a. If manual mapping is consistent, mark procedures_map.hand_map_status 'CONSISTENT'
2b. If manual mapping conflicts, mark procedures_map.hand_map_status 'CONFLICTED',
    use the manual value selected for CPT, and update sources
2c. If manual mapping is missing, mark procedures_map.hand_map_status 'MISSING',
    add 'Epic procedure codes' and CPT values, and update sources
3. Validate the procedures_map
4. Insert new mappings into rpt.Leaf_usagi.Leaf_staging
*/

-- 0. Create procedures_map table

PRINT 'Starting ''procedures.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120)

USE rpt;

IF (NOT EXISTS (SELECT *
                FROM information_schema.tables
                WHERE table_schema = 'leaf_scratch'
                AND table_name = 'procedures_map'))
    BEGIN
        CREATE TABLE leaf_scratch.procedures_map
        (
            Epic_concept_id INT NOT NULL PRIMARY KEY,
            Epic_concept_code NVARCHAR(50),
            Epic_concept_name NVARCHAR(255) NOT NULL,
            CPT4_concept_id INT,
            CPT4_concept_code NVARCHAR(50) NOT NULL UNIQUE,
            CPT4_concept_name NVARCHAR(255) NOT NULL,
            -- Relationship of Sharon's hand-coded Epic -> CPT4 mapping to automated mapping
            hand_map_status NVARCHAR(50),
            sources NVARCHAR(200) NOT NULL,     -- Sources for a record
            comment NVARCHAR(200)
        )
    END
ELSE
    DELETE FROM leaf_scratch.procedures_map


-- 1. Map 'Epic procedure codes' to CPT, from the Epic concept in src.caboodle.ProcedureDim
USE src;

-- DROP temp tables
IF OBJECT_ID(N'tempdb..#proc_mappings_from_code') IS NOT NULL
	DROP TABLE #proc_mappings_from_code
IF OBJECT_ID(N'tempdb..#proc_mappings_from_cpt_code') IS NOT NULL
	DROP TABLE #proc_mappings_from_cpt_code

-- Get mappings from Code
SELECT procedure_dim.ProcedureEpicId,
       procedure_dim.[Name] AS 'Epic_name',
       concept.concept_name,
       procedure_dim.Code AS 'Code'
INTO #proc_mappings_from_code
FROM caboodle.ProcedureDim procedure_dim,
     omop.cdm.concept concept
WHERE procedure_dim.IsCurrent = 1
      AND SUBSTRING(procedure_dim.SurgicalProcedureEpicId, 4, 5) <> procedure_dim.Code
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
      AND concept.vocabulary_id = 'CPT4'
      AND concept.concept_code  = procedure_dim.Code
GROUP BY procedure_dim.ProcedureEpicId,
         procedure_dim.[Name],
         concept.concept_name,
         procedure_dim.Code;

-- Get mappings directly from CptCode
SELECT procedure_dim.ProcedureEpicId,
       procedure_dim.[Name] AS 'Epic_name',
       concept.concept_name,
       procedure_dim.CptCode AS 'Code'
INTO #proc_mappings_from_cpt_code
FROM caboodle.ProcedureDim procedure_dim,
     omop.cdm.concept concept
WHERE procedure_dim.IsCurrent = 1
      AND procedure_dim.ProcedureEpicId IS NOT NULL
      AND NOT procedure_dim.CptCode IN ('', '*Not Applicable', '*Deleted', '*Unknown')
      -- These appear to be invalid, deleted or non-procedure codes
      AND NOT (procedure_dim.[Name] LIKE '-----%'
               OR procedure_dim.[Name] LIKE 'CODE DELETED FOR %'
               OR procedure_dim.[Name] LIKE 'DELETED %'
               OR procedure_dim.[Name] LIKE 'COPAYMENT % DOLLARS')
      -- Avoid non-Clarity data added by Population Health
      AND procedure_dim._HasSourceClarity = 1 AND procedure_dim._IsDeleted = 0
      -- Ensure procedure_dim.Code is a valid CPT4 code
      AND concept.vocabulary_id = 'CPT4'
      AND concept.concept_code  = procedure_dim.CptCode
GROUP BY procedure_dim.ProcedureEpicId,
         procedure_dim.[Name],
         concept.concept_name,
         procedure_dim.CptCode;

-- Conflicting codes from the two methods, which can be reconciled or ignored
-- Join on ProcedureEpicId, showing both Code and CptCode
IF OBJECT_ID(N'tempdb..#conflicting_proc_mappings') IS NOT NULL
	DROP TABLE #conflicting_proc_mappings;

SELECT #proc_mappings_from_cpt_code.ProcedureEpicId,
       #proc_mappings_from_cpt_code.Epic_name,
       #proc_mappings_from_cpt_code.Code AS 'CptCode_code',
       #proc_mappings_from_code.Code AS 'Code_code'
INTO #conflicting_proc_mappings
FROM #proc_mappings_from_cpt_code,
     #proc_mappings_from_code
WHERE #proc_mappings_from_cpt_code.ProcedureEpicId = #proc_mappings_from_code.ProcedureEpicId
      AND #proc_mappings_from_cpt_code.Code <> #proc_mappings_from_code.Code;

SELECT *
FROM #conflicting_proc_mappings;

-- Code mappings that do not conflict or are provided by only one method, which will be used as is
IF OBJECT_ID(N'tempdb..#non_conflicting_proc_mappings') IS NOT NULL
	DROP TABLE #non_conflicting_proc_mappings;

USE rpt;

-- Keep non-conflicting mappings from CptCode and Code, without duplication
INSERT INTO leaf_scratch.procedures_map (Epic_concept_id,
                                         Epic_concept_name,
                                         CPT4_concept_name,
                                         CPT4_concept_code,
                                         sources)
SELECT ProcedureEpicId,
       Epic_name,
       concept_name,
       Code,
       'caboodle.ProcedureDim'
FROM (SELECT *
      FROM #proc_mappings_from_cpt_code
      WHERE ProcedureEpicId NOT IN (SELECT ProcedureEpicId
                                    FROM #conflicting_proc_mappings)

      UNION

      SELECT *
      FROM #proc_mappings_from_code
      WHERE ProcedureEpicId NOT IN (SELECT ProcedureEpicId
                                    FROM #conflicting_proc_mappings)) proc_mappings;

UPDATE leaf_scratch.procedures_map
SET Epic_concept_code = Epic_concept.concept_code,
    CPT4_concept_id = CPT4_concept.concept_id
FROM omop.cdm.concept Epic_concept,
     omop.cdm.concept CPT4_concept,
     leaf_scratch.procedures_map procedures_map
WHERE procedures_map.Epic_concept_id = Epic_concept.concept_id
      AND procedures_map.CPT4_concept_code = CPT4_concept.concept_code

/*
read sharon's procedure mappings into a table_name
incorporate them into procedures_map
have Sharon review
*/
PRINT 'Finishing ''procedures.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120)
