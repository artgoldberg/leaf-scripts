/*
 * Prepare to load files with curated mappings into leaf_procedures.curated_procedure_mappings
 * Author: Arthur.Goldberg@mssm.edu
 */

-- Create SQL Server schema for various procedure tables
USE rpt;

IF (SCHEMA_ID('leaf_procedures') IS NULL)
BEGIN
    EXEC ('CREATE SCHEMA [leaf_procedures]')
END
GO

-- Create table schema for the curated procedure mappings in temp table
DROP TABLE IF EXISTS leaf_procedures.temp_curated_procedure_mappings_schema;

CREATE TABLE leaf_procedures.temp_curated_procedure_mappings_schema
(
    -- care about this:
    source_code_type VARCHAR(255),                  -- whether the source code is surgical or not
    -- care about this:
    source_code VARCHAR(255),
    -- care about this, partly:
    source_name VARCHAR(255),
    source_frequency VARCHAR(255),
    source_auto_assigned_concept_ids VARCHAR(255),
    code_set VARCHAR(255),
    code VARCHAR(255),
    match_score VARCHAR(255),
    mapping_status VARCHAR(255),
    equivalence VARCHAR(255),
    status_set_by VARCHAR(255),
    status_set_on VARCHAR(255),
    -- care about this:
    concept_id VARCHAR(255),
    -- care about this, partly:
    concept_name VARCHAR(1000),
    domain_id VARCHAR(255),
    mapping_type VARCHAR(255),
    comment VARCHAR(255),
    created_by VARCHAR(255),
    created_on VARCHAR(255)
);

-- Make table to hold curated procedure mappings
DROP TABLE IF EXISTS rpt.leaf_procedures.curated_procedure_mappings;

SELECT *
INTO rpt.leaf_procedures.curated_procedure_mappings
FROM rpt.leaf_procedures.temp_curated_procedure_mappings_schema;
