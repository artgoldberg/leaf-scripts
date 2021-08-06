use src;

DECLARE @NUM_ROWS INT = (SELECT COUNT(*)
								FROM src.usagi.mapping_import mapping_import)

PRINT CAST(@NUM_ROWS AS VARCHAR) + ' records in src.usagi.mapping_import'

SELECT *
FROM src.usagi.mapping_import mapping_import
WHERE mapping_import.target_concept_id IS NULL
	AND mapping_import.target_concept_code IS NULL
	AND mapping_import.target_concept_name IS NULL

DECLARE @NUM_USELESS_ROWS_1 INT = (SELECT COUNT(*)
								FROM src.usagi.mapping_import mapping_import
								WHERE mapping_import.target_concept_id IS NULL
									AND mapping_import.target_concept_code IS NULL
									AND mapping_import.target_concept_name IS NULL)

PRINT CAST(@NUM_USELESS_ROWS_1 AS VARCHAR) + ' records in mapping_import have no information about a target concept ' +
    '(target_concept_id, target_concept_code and target_concept_name are NULL).'

/*
SELECT *
FROM src.usagi.mapping_import mapping_import
WHERE mapping_import.source_concept_id IS NULL
	AND mapping_import.source_concept_code IS NULL
	AND mapping_import.source_concept_name IS NULL

DECLARE @NUM_USELESS_ROWS_2 INT = (SELECT COUNT(*)
								FROM src.usagi.mapping_import mapping_import
								WHERE mapping_import.source_concept_id IS NULL
									AND mapping_import.source_concept_code IS NULL
									AND mapping_import.source_concept_name IS NULL)

PRINT CAST(@NUM_USELESS_ROWS_2 AS VARCHAR) + ' records in mapping_import have no information about a source concept'
*/

DECLARE @NUM INT = 0

SET @NUM = (SELECT COUNT(*)
            FROM src.usagi.mapping_import mapping_import
            WHERE mapping_import.mapping_creation_user = 'Sharon Nirenberg')

PRINT CAST(@NUM AS VARCHAR) + ' records in mapping_import have mapping_creation_user = Sharon Nirenberg'

SET @NUM = (SELECT COUNT(*)
            FROM src.usagi.mapping_import mapping_import
            WHERE mapping_import.mapping_status_user = 'Sharon Nirenberg')

PRINT CAST(@NUM AS VARCHAR) + ' records in mapping_import have mapping_status_user = Sharon Nirenberg'

SET @NUM = (SELECT COUNT(*)
            FROM src.usagi.mapping_import mapping_import
            WHERE mapping_import.mapping_creation_user = 'Sharon Nirenberg'
            OR mapping_import.mapping_status_user = 'Sharon Nirenberg')

PRINT CAST(@NUM AS VARCHAR) + ' records in mapping_import have mapping_creation_user or mapping_status_user = Sharon Nirenberg'

SET @NUM = (SELECT COUNT(*)
            FROM src.usagi.mapping_import mapping_import
            WHERE mapping_import.target_concept_vocabulary_id = 'SNOMED')

PRINT CAST(@NUM AS VARCHAR) + ' records in mapping_import have target_concept_vocabulary_id = SNOMED'

SET @NUM = (SELECT COUNT(*)
            FROM src.usagi.mapping_import mapping_import
            WHERE mapping_import.target_concept_vocabulary_id = 'SNOMED'
            AND mapping_import.mapping_status_user = 'Sharon Nirenberg')

PRINT CAST(@NUM AS VARCHAR) + ' records in mapping_import have target_concept_vocabulary_id = SNOMED ' +
    'and mapping_status_user = Sharon Nirenberg' 

INSERT INTO SRC.USAGI.MAPPING_IMPORT(SOURCE_CONCEPT_ID,
                                     SOURCE_CONCEPT_CODE,
                                     SOURCE_CONCEPT_NAME)
SELECT 1,
       'test code',
       'test name'

PRINT ''
