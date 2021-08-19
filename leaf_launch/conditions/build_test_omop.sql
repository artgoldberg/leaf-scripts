/*
 * Create test OMOP condition and concept relationship data for testing leaf_icd10.sql
 * Author: Arthur.Goldberg@mssm.edu
 */

/*
Must be executed as goldba06@MSNYUHEALTH.ORG.

Steps:
1. create, load and index the table I need to modify: condition_occurrence
2. update condition_occurrence from Leaf_scratch.conditions_map
3. create record in LeafDB.app.ConceptSqlSet for this test condition_occurrence
4. run and test leaf_icd10.sql
*/

-- 1. create, load and index tables I need to modify: concept_relationship & condition_occurrence
PRINT 'Starting ''build_test_omop.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120)

USE rpt

IF (EXISTS (SELECT *
            FROM information_schema.tables
            WHERE table_schema = 'test_omop_conditions'
            AND table_name = 'condition_occurrence'))
BEGIN
    DROP TABLE test_omop_conditions.condition_occurrence
END

-- 100,000,000 = all
SELECT TOP 100000000 *
INTO test_omop_conditions.condition_occurrence
FROM omop.cdm_std.condition_occurrence

-- index the tables
IF NOT EXISTS(SELECT *
              FROM sys.indexes
              WHERE name = 'ix_Epic_concept_code'
              AND object_id = OBJECT_ID('leaf_scratch.conditions_map'))
    BEGIN
        CREATE UNIQUE INDEX ix_Epic_concept_code
        ON leaf_scratch.conditions_map (Epic_concept_code)
    END

IF NOT EXISTS(SELECT *
              FROM sys.indexes
              WHERE name = 'ix_ICD10_concept_code'
              AND object_id = OBJECT_ID('leaf_scratch.conditions_map'))
    BEGIN
        CREATE INDEX ix_ICD10_concept_code
        ON leaf_scratch.conditions_map (ICD10_concept_code)
    END

IF NOT EXISTS(SELECT *
              FROM sys.indexes
              WHERE name = 'ix_SNOMED_concept_code'
              AND object_id = OBJECT_ID('leaf_scratch.conditions_map'))
    BEGIN
        CREATE INDEX ix_SNOMED_concept_code
        ON leaf_scratch.conditions_map (SNOMED_concept_code)
    END

IF NOT EXISTS(SELECT *
              FROM sys.indexes
              WHERE name = 'ix_condition_source_concept_id'
              AND object_id = OBJECT_ID('test_omop_conditions.condition_occurrence'))
    BEGIN
        CREATE INDEX ix_condition_source_concept_id
        ON test_omop_conditions.condition_occurrence (condition_source_concept_id)
    END;

PRINT '1: Completed loading of condition_occurrence and indexing of it and conditions_map'

DECLARE @num_condition_occurrence_records BIGINT = (SELECT COUNT(*)
                                                    FROM test_omop_conditions.condition_occurrence)
PRINT CAST(@num_condition_occurrence_records AS VARCHAR) + ' records in condition_occurrence'

-- 2. update condition_occurrence from leaf_scratch.conditions_map

-- update condition_occurrence fields with conditions_map SNOMED info:
/*
-- Query for testing UPDATE below
SELECT SNOMED_concept_id,
       SNOMED_concept_code,
       SNOMED_concept_name,
       condition_source_concept_code Epic_concept_code,
       condition_source_concept_name Epic_concept_name
FROM test_omop_conditions.condition_occurrence,
     leaf_scratch.conditions_map
WHERE NOT condition_source_concept_id = 0
      AND condition_source_concept_id = Epic_concept_id
*/

UPDATE test_omop_conditions.condition_occurrence
SET condition_concept_id = SNOMED_concept_id,
    condition_concept_code = SNOMED_concept_code,
    condition_concept_name = SNOMED_concept_name
FROM test_omop_conditions.condition_occurrence,
     leaf_scratch.conditions_map
WHERE NOT condition_source_concept_id = 0
      AND condition_source_concept_id = Epic_concept_id

DECLARE @num_condition_occurrences_w_omop_concepts BIGINT = (SELECT COUNT(*)
                                                             FROM test_omop_conditions.condition_occurrence
                                                             WHERE condition_concept_id <> 0)
PRINT CAST(@num_condition_occurrences_w_omop_concepts AS VARCHAR) +
    ' records in condition_occurrence have SNOMED concepts after mapping'

PRINT CAST(100 * @num_condition_occurrences_w_omop_concepts / @num_condition_occurrence_records AS VARCHAR) +
    '% of condition_occurrence records have SNOMED concepts after mapping'

DECLARE @num_condition_occurrences_w_Epic_concepts BIGINT = (SELECT COUNT(*)
                                                             FROM test_omop_conditions.condition_occurrence
                                                             WHERE condition_source_concept_id <> 0)

PRINT CAST(100 * @num_condition_occurrences_w_Epic_concepts / @num_condition_occurrence_records AS VARCHAR) +
	'% of condition_occurrence records have Epic diagnoses'

PRINT CAST(100 * @num_condition_occurrences_w_omop_concepts / @num_condition_occurrences_w_Epic_concepts AS VARCHAR) +
	'% of condition_occurrence records with initialized Epic diagnosis have mapped SNOMED concepts'

PRINT 'Completed update condition_occurrence fields with conditions_map SNOMED info'

-- todo: 3. create record in LeafDB.app.ConceptSqlSet for this test condition_occurrence

PRINT 'Finishing ''build_test_omop.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT ''
