-- Prepare temp_curated_procedure_mappings to hold data loaded by BCP
DROP TABLE IF EXISTS rpt.leaf_scratch.temp_curated_procedure_mappings;

SELECT *
INTO rpt.leaf_scratch.temp_curated_procedure_mappings
FROM rpt.leaf_scratch.temp_curated_procedure_mappings_schema;
