/*
 * Prepare to load one file of curated mappings into leaf_procedures.curated_procedure_mappings
 * Author: Arthur.Goldberg@mssm.edu
 */

-- Prepare temp_curated_procedure_mappings to hold data loaded by BCP
DROP TABLE IF EXISTS rpt.leaf_procedures.temp_curated_procedure_mappings;

SELECT *
INTO rpt.leaf_procedures.temp_curated_procedure_mappings
FROM rpt.leaf_procedures.temp_curated_procedure_mappings_schema;
