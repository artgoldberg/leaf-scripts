/*
 * Check on presence of procedure_source_concept_id in procedure_occurrence
 * Author: Arthur.Goldberg@mssm.edu
 */

USE omop;

SELECT 'cdm' AS 'Schema',
       'Procedures' AS 'Code',
       COUNT(*) AS 'Count',
       procedure_source_concept_id,
       '',
       '',
       procedure_source_value
FROM cdm.procedure_occurrence
WHERE procedure_source_concept_id IS NOT NULL
      AND 0 < procedure_source_concept_id
      AND procedure_source_value IS NOT NULL
GROUP BY procedure_source_concept_id, procedure_source_value;

SELECT 'cdm_std' AS 'Schema',
       'Procedures' AS 'Code',
       COUNT(*) AS 'Count',
       procedure_source_concept_id,
       procedure_source_concept_code,
       procedure_source_concept_name,
       procedure_source_value
FROM cdm_std.procedure_occurrence
WHERE procedure_source_concept_id IS NOT NULL
      AND 0 < procedure_source_concept_id
      AND procedure_source_concept_code IS NOT NULL
      AND procedure_source_concept_name IS NOT NULL
      AND procedure_source_value IS NOT NULL
GROUP BY procedure_source_concept_id,
         procedure_source_concept_code,
         procedure_source_concept_name,
         procedure_source_value
