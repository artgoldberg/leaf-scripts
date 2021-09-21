-- Insert the curated mappings recently imported from a file into curated_procedure_mappings
INSERT INTO rpt.leaf_scratch.curated_procedure_mappings
SELECT *
FROM rpt.leaf_scratch.temp_curated_procedure_mappings;
