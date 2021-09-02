/*
To test Leaf with cdm_deid_std and rpt.test_omop_conditions.condition_occurrence,
replace all person_ids in this condition_occurrence with de-identified IDs.
 */

PRINT 'Starting ''set_rpt_person_ids_to_de_id_ids.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120);

DECLARE @num_cdm_deid_std_condition_occurrence INT = (SELECT COUNT(*)
                                                      FROM omop.cdm_deid_std.condition_occurrence)
PRINT CAST(@num_cdm_deid_std_condition_occurrence AS VARCHAR) +
      ' records in omop.cdm_deid_std.condition_occurrence'

DECLARE @num_test_omop_conditions_condition_occurrence INT = (SELECT COUNT(*)
                                                              FROM rpt.test_omop_conditions.condition_occurrence)
PRINT CAST(@num_test_omop_conditions_condition_occurrence AS VARCHAR) +
      ' records in rpt.test_omop_conditions.condition_occurrence'

/*
-- View pairs of PHI person_ids, their de-identified person_ids
SELECT condition_occurrence.person_id,
       HASHBYTES('SHA2_256', CONCAT(condition_occurrence.person_id, patient_secret.salt_value)) as deid_person_id
FROM rpt.test_omop_conditions.condition_occurrence condition_occurrence
    JOIN omop_stg.etl_metadata.patient_secret patient_secret
    ON condition_occurrence.person_id = patient_secret.person_id;
*/

-- Create a table which contains a copy of my condition_occurrence table and will use de-identified person_ids
USE rpt;

IF (EXISTS (SELECT *
            FROM information_schema.tables
            WHERE table_schema = 'test_omop_conditions'
            AND table_name = 'condition_occurrence_deid'))
BEGIN
    DROP TABLE test_omop_conditions.condition_occurrence_deid
END;

PRINT 'Copying test_omop_conditions.condition_occurrence at ' + CONVERT(VARCHAR, GETDATE(), 120);

SELECT *
INTO test_omop_conditions.condition_occurrence_deid
FROM test_omop_conditions.condition_occurrence;

PRINT 'EXEC sp_rename at ' + CONVERT(VARCHAR, GETDATE(), 120);

-- Rename person_id in condition_occurrence_deid to PHI_person_id, which will be ignored, except below
EXEC sp_rename 'test_omop_conditions.condition_occurrence_deid.person_id', 'PHI_person_id', 'COLUMN';

-- GO, so lame SQL Server won't compile the code below with PHI_person_id and throw invalid error before PHI_person_id is made
GO

-- Create index on PHI_person_id
CREATE INDEX ix_PHI_person_id
ON test_omop_conditions.condition_occurrence_deid (PHI_person_id)

-- Create BINARY(32) person_id column to hold de-identified person identifier in condition_occurrence_deid
ALTER TABLE test_omop_conditions.condition_occurrence_deid
ADD person_id BINARY(32);

PRINT 'Store de-identified person_id in condition_occurrence_deid at ' + CONVERT(VARCHAR, GETDATE(), 120);

DECLARE @SQL NVARCHAR(1000)
SELECT @SQL = N'UPDATE condition_occurrence_deid
                SET condition_occurrence_deid.person_id = 
                    HASHBYTES(''SHA2_256''', CONCAT(condition_occurrence_deid.PHI_person_id, patient_secret.salt_value))
                FROM test_omop_conditions.condition_occurrence_deid condition_occurrence_deid
                     JOIN omop_stg.etl_metadata.patient_secret patient_secret
                     ON condition_occurrence_deid.PHI_person_id = patient_secret.person_id;'
EXEC sp_executesql @SQL

/*
-- Update person_id in condition_occurrence_deid to a de-identified transformation of its PHI_person_id
UPDATE condition_occurrence_deid
SET condition_occurrence_deid.person_id = 
    HASHBYTES('SHA2_256', CONCAT(condition_occurrence_deid.PHI_person_id, patient_secret.salt_value))
FROM test_omop_conditions.condition_occurrence_deid condition_occurrence_deid
     JOIN omop_stg.etl_metadata.patient_secret patient_secret
     ON condition_occurrence_deid.PHI_person_id = patient_secret.person_id;

-- Lastly, modify Leaf to access condition_occurrence_deid instead of test_omop_conditions.condition_occurrence
-- Do this by hand

*/

PRINT 'Finishing ''set_rpt_person_ids_to_de_id_ids.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120)
