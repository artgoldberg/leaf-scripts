-- todo: describe
DROP TABLE IF EXISTS #curated_concept_mappings;

CREATE TABLE #curated_concept_mappings
(
    -- Care about this:
    SOURCE_CODE VARCHAR(255),
    -- Care about this, partly:
    SOURCE_NAME VARCHAR(255),
    SOURCE_FREQUENCY VARCHAR(255),
    SOURCE_AUTO_ASSIGNED_CONCEPT_IDS VARCHAR(255),
    IGNORE_1 VARCHAR(255),
    IGNORE_2 VARCHAR(255),
    MATCH_SCORE VARCHAR(255),
    MAPPING_STATUS VARCHAR(255),
    EQUIVALENCE VARCHAR(255),
    STATUS_SET_BY VARCHAR(255),
    STATUS_SET_ON VARCHAR(255),
    -- Care about this:
    CONCEPT_ID VARCHAR(255),
    -- Care about this, partly:
    CONCEPT_NAME VARCHAR(1000),
    DOMAIN_ID VARCHAR(255),
    MAPPING_TYPE VARCHAR(255),
    COMMENT VARCHAR(255),
    CREATED_BY VARCHAR(255),
    CREATED_ON VARCHAR(255)
);

DROP TABLE IF EXISTS rpt.leaf_scratch.temp_curated_procedure_mappings;

SELECT *
INTO rpt.leaf_scratch.temp_curated_procedure_mappings
FROM #curated_concept_mappings;
