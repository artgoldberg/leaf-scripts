/*
 * Finish loading one file of curated mappings into leaf_procedures.curated_procedure_mappings
 * Author: Arthur.Goldberg@mssm.edu
 */

-- Insert the curated mappings recently imported from a file into curated_procedure_mappings
INSERT INTO rpt.leaf_procedures.curated_procedure_mappings
SELECT *
FROM rpt.leaf_procedures.temp_curated_procedure_mappings;
