DROP TABLE IF EXISTS #curated_concept_mappings;

CREATE TABLE #curated_concept_mappings
(
    -- Care about this:
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

DROP TABLE IF EXISTS rpt.leaf_scratch.curated_procedure_mappings;

SELECT *
INTO rpt.leaf_scratch.curated_procedure_mappings
FROM #curated_concept_mappings;
