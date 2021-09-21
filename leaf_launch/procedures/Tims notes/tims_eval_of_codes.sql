/*
 * Examine the procedure codes in SurgicalProcedureEventFact (if it exists) and ProcedureDim
 * From Tim's email on "Additional tables desired in src.caboodle"
 */

USE src;

/*
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
      AND concept.concept_code  = procedure_dim.Code
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

-- Mappings from CptCode and Code
SELECT *
INTO #non_conflicting_proc_mappings
FROM (SELECT *
      FROM #proc_mappings_from_cpt_code
      WHERE ProcedureEpicId NOT IN (SELECT ProcedureEpicId
                                    FROM #conflicting_proc_mappings)

      UNION

      SELECT *
      FROM #proc_mappings_from_code
      WHERE ProcedureEpicId NOT IN (SELECT ProcedureEpicId
                                    FROM #conflicting_proc_mappings)) table_alias;

SELECT *
FROM #non_conflicting_proc_mappings;
*/

-- Tim's note: "Sharon determined that the numeric-only SurgicalProcedureEpicId values
-- (ie, the ones that do not start with “M”) almost always contain the CPT code embedded in the 4th through 8th position"
-- TODO: check that 'CPT Code' is a CPT Code in omop concept
SELECT procedure_dim.SurgicalProcedureEpicId AS 'Epic Id',
       SUBSTRING(procedure_dim.SurgicalProcedureEpicId, 4, 5) AS 'CPT Code',
       procedure_dim.[Name]
FROM caboodle.ProcedureDim procedure_dim
WHERE NOT procedure_dim.SurgicalProcedureEpicId LIKE 'M%'
      AND procedure_dim.SurgicalProcedureEpicId NOT IN ('*Not Applicable', '*Unknown')
      AND 8 <= LEN(procedure_dim.SurgicalProcedureEpicId)
      AND procedure_dim.IsCurrent = 1
      -- Avoid non-Clarity data added by Population Health
      AND procedure_dim._HasSourceClarity = 1 AND procedure_dim._IsDeleted = 0
GROUP BY procedure_dim.ProcedureEpicId,
         procedure_dim.[Name],
         procedure_dim.SurgicalProcedureEpicId

/*
-- Tim's query; doesn't work as SurgicalProcedureEventFact isn't in caboodle
SELECT procedure_dim.ProcedureEpicId,
       procedure_dim.SurgicalProcedureEpicId,
       procedure_dim.Code,
       procedure_dim.CodeSet,
       curr_proc_dim.ProcedureEpicId,
       curr_proc_dim.SurgicalProcedureEpicId,
       curr_proc_dim.Code,
       curr_proc_dim.CodeSet,
       COUNT(*)
FROM caboodle.SurgicalProcedureEventFact surgical_procedure_event_fact
     JOIN caboodle.ProcedureDim procedure_dim
          ON surgical_procedure_event_fact.ProcedureDurableKey = procedure_dim.DurableKey
          AND procedure_dim.IsCurrent = 1
     JOIN caboodle.ProcedureDim curr_proc_dim
          ON surgical_procedure_event_fact.ProcedureCodeDurableKey = curr_proc_dim.DurableKey
          AND curr_proc_dim.IsCurrent = 1
WHERE surgical_procedure_event_fact.ProcedureDurableKey > 0
      AND surgical_procedure_event_fact.ProcedureCodeDurableKey > 0
      AND SUBSTRING(procedure_dim.SurgicalProcedureEpicId, 4, 5) != curr_proc_dim.Code
      AND curr_proc_dim.Code != '*Unspecified'
GROUP BY procedure_dim.ProcedureEpicId,
         procedure_dim.SurgicalProcedureEpicId,
         procedure_dim.Code,
         procedure_dim.CodeSet,
         curr_proc_dim.ProcedureEpicId,
         curr_proc_dim.SurgicalProcedureEpicId,
         curr_proc_dim.Code,
         curr_proc_dim.CodeSet
*/
