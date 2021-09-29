/*
 * Clean up from loading files with curated mappings into leaf_procedures.curated_procedure_mappings
 * Author: Arthur.Goldberg@mssm.edu
 */

USE rpt;

-- Drop temp table for the schema for the curated procedure mappings
DROP TABLE IF EXISTS leaf_procedures.temp_curated_procedure_mappings_schema;

-- Remove duplicates
DROP TABLE IF EXISTS leaf_procedures.curated_procedure_mappings_full_duplicates;
SELECT *,
       ROW_NUMBER() OVER (PARTITION BY source_code_type,
                                       source_code,
                                       source_name,
                                       source_frequency,
                                       source_auto_assigned_concept_ids,
                                       code_set,
                                       code,
                                       match_score,
                                       mapping_status,
                                       equivalence,
                                       status_set_by,
                                       status_set_on,
                                       concept_id,
                                       concept_name,
                                       domain_id,
                                       mapping_type,
                                       comment,
                                       created_by,
                                       created_on
                          ORDER BY source_code_type,
                                   source_code,
                                   source_name,
                                   source_frequency,
                                   source_auto_assigned_concept_ids,
                                   code_set,
                                   code,
                                   match_score,
                                   mapping_status,
                                   equivalence,
                                   status_set_by,
                                   status_set_on,
                                   concept_id,
                                   concept_name,
                                   domain_id,
                                   mapping_type,
                                   comment,
                                   created_by,
                                   created_on) AS row_number
INTO leaf_procedures.curated_procedure_mappings_full_duplicates
FROM leaf_procedures.curated_procedure_mappings

-- TODO: finish this
-- Procedure to print table name, number unique rows, number duplicated rows
-- IF OBJECT_ID('tempdb..#evaluate_mapping_duplicates') IS NOT NULL
-- BEGIN
--     DROP PROC #evaluate_mapping_duplicates
-- END
-- GO
--
-- CREATE PROCEDURE #evaluate_mapping_duplicates
-- 	@table_name NVARCHAR(MAX)
-- AS
-- BEGIN
--     DECLARE @nl CHAR = CHAR(10) -- new line char
--     DECLARE @sql NVARCHAR(MAX) = CONCAT('SELECT COUNT(*)', @nl,
-- 						    			'FROM leaf_procedures.',
-- 						    			 @table_name, @nl,
-- 						    			 'WHERE row_number <= 1', @nl)
--     EXEC (@sql)
--
-- END

DELETE FROM leaf_procedures.curated_procedure_mappings_full_duplicates
WHERE row_number <= 1

DROP TABLE IF EXISTS leaf_procedures.curated_procedure_mappings_primary_key_duplicates;
SELECT *,
       ROW_NUMBER() OVER (PARTITION BY source_code_type,
                                       source_code,
                                       concept_id
                          ORDER BY source_code_type,
                                   source_code,
                                   concept_id) AS row_number
INTO leaf_procedures.curated_procedure_mappings_primary_key_duplicates
FROM leaf_procedures.curated_procedure_mappings

DELETE FROM leaf_procedures.curated_procedure_mappings_primary_key_duplicates
WHERE row_number <= 1

-- Delete duplicated primary keys from curated_procedure_mappings
;WITH row_counts AS (SELECT *,
                           ROW_NUMBER() OVER (PARTITION BY source_code_type,
                                                           source_code,
                                                           concept_id
                                              ORDER BY source_code_type,
                                                       source_code,
                                                       concept_id) AS row_number
                    FROM leaf_procedures.curated_procedure_mappings)
DELETE FROM row_counts
WHERE 1 < row_number

DROP TABLE IF EXISTS leaf_procedures.curated_procedure_mappings_primary_key_duplicates_remaining;
SELECT *,
       ROW_NUMBER() OVER (PARTITION BY source_code_type,
                                       source_code,
                                       concept_id
                          ORDER BY source_code_type,
                                   source_code,
                                   concept_id) AS row_number
INTO leaf_procedures.curated_procedure_mappings_primary_key_duplicates_remaining
FROM leaf_procedures.curated_procedure_mappings

DELETE FROM leaf_procedures.curated_procedure_mappings_primary_key_duplicates_remaining
WHERE row_number <= 1
-- TODO: report that this finds no duplicates in leaf_procedures.curated_procedure_mappings

-- TODO: delete tables that aren't needed
