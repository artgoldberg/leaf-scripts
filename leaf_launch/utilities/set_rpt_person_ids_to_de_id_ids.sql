/*
 * To test Leaf with cdm_deid_std and condition_occurrence, replace person_ids in
 * rpt.test_omop_conditions.condition_occurrence with de-identified IDs.
 * Author: Arthur.Goldberg@mssm.edu
 * Author: Joseph.Nahmias@mountsinai.org
 */

-- SET STATISTICS TIME, IO ON;

DECLARE @msg NVARCHAR(MAX) = 'Starting ''set_rpt_person_ids_to_de_id_ids.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

DECLARE @num_cdm_deid_std_condition_occurrence INT = (SELECT COUNT(*)
                                                      FROM omop.cdm_deid_std.condition_occurrence);
SET @msg = CAST(@num_cdm_deid_std_condition_occurrence AS VARCHAR) +
                ' records in omop.cdm_deid_std.condition_occurrence';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

DECLARE @num_test_omop_conditions_condition_occurrence INT = (SELECT COUNT(*)
                                                              FROM rpt.test_omop_conditions.condition_occurrence);
SET @msg = CAST(@num_test_omop_conditions_condition_occurrence AS VARCHAR) +
                ' records in rpt.test_omop_conditions.condition_occurrence';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

/*
-- View pairs of PHI person_ids, their de-identified person_ids
SELECT condition_occurrence.person_id,
       HASHBYTES('SHA2_256', CONCAT(condition_occurrence.person_id, patient_secret.salt_value)) as deid_person_id
FROM rpt.test_omop_conditions.condition_occurrence condition_occurrence
    JOIN omop_stg.etl_metadata.patient_secret patient_secret
    ON condition_occurrence.person_id = patient_secret.person_id;
*/

-- Create temporary table with all person_ids and their de-identified equivalents
SET @msg = 'Start making temporary table with all person_ids and their de-identified equivalents at ' +
           CONVERT(VARCHAR, GETDATE(), 120);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

DROP TABLE IF EXISTS #deid_mapping;
SELECT person_id,
       deid_person_id = HASHBYTES('SHA2_256', CONCAT(person_id, salt_value))
INTO #deid_mapping
FROM omop_stg.etl_metadata.patient_secret;

CREATE CLUSTERED INDEX ci_deid_mapping ON #deid_mapping (person_id);

GO

-- Create a table which contains a copy of my condition_occurrence table and will use de-identified person_ids
USE rpt;

DECLARE @msg NVARCHAR(MAX) = 'Start removing test_omop_conditions.condition_occurrence_deid at ' + CONVERT(VARCHAR, GETDATE(), 120);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF (EXISTS (SELECT *
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = 'test_omop_conditions'
                  AND TABLE_NAME = 'condition_occurrence_deid'))
BEGIN
    TRUNCATE TABLE test_omop_conditions.condition_occurrence_deid;
END
DROP TABLE IF EXISTS test_omop_conditions.condition_occurrence_deid;

SET @msg = 'Start creating condition_occurrence_deid at ' + CONVERT(VARCHAR, GETDATE(), 120);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

SELECT
  co.condition_occurrence_id,
  co.condition_type_concept_id,
  co.condition_type_concept_code,
  co.condition_type_concept_name,
  co.visit_occurrence_id,
  co.visit_detail_id,
  person_id = map.deid_person_id,
  co.provider_id,
  co.condition_concept_id,
  co.condition_concept_code,
  co.condition_concept_name,
  co.condition_source_concept_id,
  co.condition_source_concept_code,
  co.condition_source_concept_name,
  co.condition_source_value,
  co.condition_status_concept_id,
  co.condition_status_concept_code,
  co.condition_status_concept_name,
  co.condition_status_source_value,
  co.condition_start_date,
  co.condition_start_datetime,
  co.condition_end_date,
  co.condition_end_datetime,
  co.stop_reason
INTO test_omop_conditions.condition_occurrence_deid
FROM test_omop_conditions.condition_occurrence co
     JOIN #deid_mapping map ON map.person_id = co.person_id;

DECLARE @num_condition_occurrence_deid INT = (SELECT COUNT(*)
                                              FROM test_omop_conditions.condition_occurrence_deid);
SET @msg = CAST(@num_condition_occurrence_deid AS VARCHAR) +
                ' records in test_omop_conditions.condition_occurrence_deid';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

SET @msg = 'Finishing ''set_rpt_person_ids_to_de_id_ids.sql'' at ' + CONVERT(VARCHAR, GETDATE(), 120);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- Lastly, modify Leaf to access condition_occurrence_deid instead of test_omop_conditions.condition_occurrence
-- Do this by hand
