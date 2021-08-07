/*
 * Create test OMOP condition and concept relationship data for testing leaf_icd10.sql
 * Author: Arthur.Goldberg@mssm.edu
 */

/*
Must be executed as goldba06@MSNYUHEALTH.ORG.

Steps:
1. create, load and index tables I need to modify: concept_relationship & condition_occurrence
2. update concept_relationship & condition_occurrence from leaf_scratch.diagnosis_map
3. create record in LeafDB.app.ConceptSqlSet for this test condition_occurrence
4. revise leaf_icd10.sql to use these tables
5. run and test leaf_icd10.sql
*/

-- 1. create, load and index tables I need to modify: concept_relationship & condition_occurrence
PRINT 'Starting ''build_test_omop.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120)

USE rpt

IF (EXISTS (SELECT *
            FROM information_schema.tables
            WHERE table_schema = 'test_omop_conditions'
            AND table_name = 'concept_relationship'))
BEGIN
    DROP TABLE test_omop_conditions.concept_relationship
END

SELECT TOP 1000000 *
INTO test_omop_conditions.concept_relationship
FROM omop.cdm_std.concept_relationship

IF (EXISTS (SELECT *
            FROM information_schema.tables
            WHERE table_schema = 'test_omop_conditions'
            AND table_name = 'condition_occurrence'))
BEGIN
    DROP TABLE test_omop_conditions.condition_occurrence
END

SELECT TOP 1000000 *
INTO test_omop_conditions.condition_occurrence
FROM omop.cdm_std.condition_occurrence

-- index the tables
IF NOT EXISTS(SELECT *
              FROM sys.indexes
              WHERE name = 'ix_Epic_concept_code'
              AND object_id = OBJECT_ID('leaf_scratch.diagnosis_map'))
    BEGIN
        CREATE UNIQUE INDEX ix_Epic_concept_code
        ON leaf_scratch.diagnosis_map (Epic_concept_code)
    END

IF NOT EXISTS(SELECT *
              FROM sys.indexes
              WHERE name = 'ix_ICD10_concept_code'
              AND object_id = OBJECT_ID('leaf_scratch.diagnosis_map'))
    BEGIN
        CREATE INDEX ix_ICD10_concept_code
        ON leaf_scratch.diagnosis_map (ICD10_concept_code)
    END

IF NOT EXISTS(SELECT *
              FROM sys.indexes
              WHERE name = 'ix_SNOMED_concept_code'
              AND object_id = OBJECT_ID('leaf_scratch.diagnosis_map'))
    BEGIN
        CREATE INDEX ix_SNOMED_concept_code
        ON leaf_scratch.diagnosis_map (SNOMED_concept_code)
    END

IF NOT EXISTS(SELECT *
              FROM sys.indexes
              WHERE name = 'ix_condition_source_concept_id'
              AND object_id = OBJECT_ID('test_omop_conditions.condition_occurrence'))
    BEGIN
        CREATE INDEX ix_condition_source_concept_id
        ON test_omop_conditions.condition_occurrence (condition_source_concept_id)
    END;

PRINT '1: Completed loading and indexing'


-- 2. update concept_relationship & condition_occurrence from leaf_scratch.diagnosis_map
-- insert diagnosis_map SNOMED to ICD10 relationships into concept_relationship
    -- ICD10 'Maps to' SNOMED required
/*
-- SELECT to check the INSERT below
SELECT DISTINCT concept_ICD10.concept_id ICD10_concept_id,
                concept_ICD10.concept_code ICD10_concept_code,
                concept_ICD10.concept_name ICD10_concept_name,
                concept_SNOMED.concept_id SNOMED_concept_id,
                concept_SNOMED.concept_code SNOMED_concept_code,
                concept_SNOMED.concept_name SNOMED_concept_name
FROM leaf_scratch.diagnosis_map diagnosis_map,
     omop.cdm_std.concept concept_ICD10,
     omop.cdm_std.concept concept_SNOMED    
WHERE concept_ICD10.vocabulary_id = 'ICD10CM'
      AND concept_ICD10.concept_code = diagnosis_map.ICD10_concept_code
      AND concept_SNOMED.vocabulary_id = 'SNOMED'
      AND concept_SNOMED.concept_code = diagnosis_map.SNOMED_concept_code

Not needed, as the relationships are already in concept_relationship
INSERT INTO test_omop_conditions.concept_relationship(concept_id_1,
                                                      concept_id_2,
                                                      relationship_id,
                                                      valid_start_date,
                                                      valid_end_date)
    SELECT DISTINCT concept_ICD10.concept_id,
                    concept_SNOMED.concept_id,
                    'Maps to',
                    CONVERT(DATE, GETDATE()),
                    DATEADD(YEAR, 10, CONVERT(DATE, GETDATE()))
    FROM leaf_scratch.diagnosis_map diagnosis_map,
         omop.cdm_std.concept concept_ICD10,
         omop.cdm_std.concept concept_SNOMED         
    WHERE concept_ICD10.vocabulary_id = 'ICD10CM'
          AND concept_ICD10.concept_code = diagnosis_map.ICD10_concept_code
          AND concept_SNOMED.vocabulary_id = 'SNOMED'
          AND concept_SNOMED.concept_code = diagnosis_map.SNOMED_concept_code;

PRINT 'Completed update concept_relationship & condition_occurrence from leaf_scratch.diagnosis_map'
*/

-- update condition_occurrence fields with diagnosis_map SNOMED info:
/*
Query for testing UPDATE below
SELECT condition_occurrence.condition_occurrence_id,
       concept_SNOMED.concept_id SNOMED_concept_id,
       concept_SNOMED.concept_code SNOMED_concept_code,
       concept_SNOMED.concept_name SNOMED_concept_name,
       concept_Epic.concept_code Epic_concept_code,
       concept_Epic.concept_name Epic_concept_name       
FROM test_omop_conditions.condition_occurrence condition_occurrence,
     leaf_scratch.diagnosis_map diagnosis_map,
     omop.cdm_std.concept concept_Epic,
     omop.cdm_std.concept concept_SNOMED
WHERE NOT condition_occurrence.condition_source_concept_id = 0
      AND condition_occurrence.condition_source_concept_id = concept_Epic.concept_id
      AND concept_Epic.concept_code = diagnosis_map.Epic_concept_code
      AND concept_Epic.vocabulary_id = 'EPIC EDG .1'
      AND diagnosis_map.SNOMED_concept_code = concept_SNOMED.concept_code
      AND concept_SNOMED.vocabulary_id = 'SNOMED'
ORDER BY concept_SNOMED.concept_id,
       concept_SNOMED.concept_code,
       concept_SNOMED.concept_name,
       concept_Epic.concept_code,
       concept_Epic.concept_name
*/

UPDATE test_omop_conditions.condition_occurrence
SET condition_concept_id = concept_SNOMED.concept_id,
    condition_concept_code = concept_SNOMED.concept_code,
    condition_concept_name = concept_SNOMED.concept_name
FROM test_omop_conditions.condition_occurrence condition_occurrence,
     leaf_scratch.diagnosis_map diagnosis_map,
     omop.cdm_std.concept concept_Epic,
     omop.cdm_std.concept concept_SNOMED
WHERE NOT condition_occurrence.condition_source_concept_id = 0
      AND condition_occurrence.condition_source_concept_id = concept_Epic.concept_id
      AND concept_Epic.concept_code = diagnosis_map.Epic_concept_code
      AND concept_Epic.vocabulary_id = 'EPIC EDG .1'
      AND diagnosis_map.SNOMED_concept_code = concept_SNOMED.concept_code
      AND concept_SNOMED.vocabulary_id = 'SNOMED'

PRINT 'Completed update condition_occurrence fields with diagnosis_map SNOMED info'

-- 3. create record in LeafDB.app.ConceptSqlSet for this test condition_occurrence

PRINT 'Finishing ''build_test_omop.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT ''

-- 5. run leaf_icd10.sql
