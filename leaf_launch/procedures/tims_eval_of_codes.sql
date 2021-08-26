/*
 * Examine the procedure codes in SurgicalProcedureEventFact (if it exists) and ProcedureDim
 * From Tim's email on "Additional tables desired in src.caboodle"
 */

USE src;

SELECT procedure_dim.ProcedureEpicId,
       procedure_dim.[Name],
       procedure_dim.Code,
       procedure_dim.CodeSet,
       COUNT(*) [count]
FROM caboodle.ProcedureDim procedure_dim
WHERE procedure_dim.IsCurrent = 1
      AND SUBSTRING(procedure_dim.SurgicalProcedureEpicId, 4, 5) <> procedure_dim.Code
      AND procedure_dim.Code != '*Unspecified'
      AND procedure_dim.ProcedureEpicId IS NOT NULL
      -- These appear to be invalid, deleted or non-procedure codes
      AND NOT procedure_dim.[Name] LIKE '-----%'
      AND NOT procedure_dim.[Name] LIKE 'CODE DELETED FOR %'
      AND NOT procedure_dim.[Name] LIKE 'COPAYMENT % DOLLARS'
      AND NOT procedure_dim.[Name] LIKE 'DELETED %'
      AND procedure_dim.CodeSet = 'CPT(R)'
-- todo: add the Avoid non-Clarity data added by Population Health condition
GROUP BY procedure_dim.ProcedureEpicId,
         procedure_dim.[Name],
         procedure_dim.Code,
         procedure_dim.CodeSet;

-- Try to get mappings directly from CptCode
SELECT procedure_dim.ProcedureEpicId,
       procedure_dim.[Name],
       procedure_dim.CptCode,
       'CPT(R)' AS 'CodeSet',
       COUNT(*) [count]
FROM caboodle.ProcedureDim procedure_dim
WHERE procedure_dim.IsCurrent = 1
      AND procedure_dim.ProcedureEpicId IS NOT NULL
      -- These appear to be invalid, deleted or non-procedure codes
      AND NOT procedure_dim.[Name] LIKE '-----%'
      AND NOT procedure_dim.[Name] LIKE 'CODE DELETED FOR %'
      AND NOT procedure_dim.[Name] LIKE 'COPAYMENT % DOLLARS'
      AND NOT procedure_dim.[Name] LIKE 'DELETED %'
      -- Deliberately not obtaining empty CptCodes
      AND NOT procedure_dim.CptCode IN ('', '*Not Applicable', '*Deleted', '*Unknown')
-- todo: add the Avoid non-Clarity data added by Population Health condition
GROUP BY procedure_dim.ProcedureEpicId,
         procedure_dim.[Name],
         procedure_dim.CptCode;

/*
Use this to determine the differences between the results of these two SELECTS:
SELECT * FROM TableA
UNION
SELECT * FROM TableB
EXCEPT
SELECT * FROM TableA
INTERSECT
SELECT * FROM TableB
*/
/*
-- Despite Tim's note "Sharon determined that the numeric-only SurgicalProcedureEpicId values
-- (ie, the ones that do not start with “M”) almost always contain the CPT code embedded in the 4th through 8th position",
-- this finds nothing as procedure_dim.SurgicalProcedureEpicId = '*Not Applicable' always
SELECT procedure_dim.ProcedureEpicId,
       procedure_dim.[Name],
       procedure_dim.SurgicalProcedureEpicId,
       SUBSTRING(procedure_dim.SurgicalProcedureEpicId, 4, 5) AS 'Code',
       procedure_dim.CodeSet,
       COUNT(*) [count]
FROM caboodle.ProcedureDim procedure_dim
WHERE procedure_dim.IsCurrent = 1
      AND NOT procedure_dim.SurgicalProcedureEpicId LIKE 'M%'
      -- AND procedure_dim.Code != '*Unspecified'
      AND procedure_dim.ProcedureEpicId IS NOT NULL
      -- These appear to be invalid, deleted or non-procedure codes
      AND NOT procedure_dim.[Name] LIKE '-----%'
      AND NOT procedure_dim.[Name] LIKE 'CODE DELETED FOR %'
      AND NOT procedure_dim.[Name] LIKE 'COPAYMENT % DOLLARS'
      AND NOT procedure_dim.[Name] LIKE 'DELETED %'
-- todo: add the Avoid non-Clarity data added by Population Health condition
GROUP BY procedure_dim.ProcedureEpicId,
         procedure_dim.[Name],
         procedure_dim.SurgicalProcedureEpicId,
         procedure_dim.CodeSet
*/

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
