-- todo: describe
INSERT INTO rpt.leaf_scratch.curated_procedure_mappings
SELECT *
FROM rpt.leaf_scratch.temp_curated_procedure_mappings;
