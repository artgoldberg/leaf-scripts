/**
 * Leaf OMOP 5.3 bootstrap script.
 * Assumptions: The script assumes your app.ConceptSqlSet table is empty,
 *              or at least has no sqlsets of identical names.
 * License: MIT
 */

DECLARE @user NVARCHAR(20) = 'bootstrap_omop.sql'
DECLARE @yes BIT = 1
DECLARE @no  BIT = 0

/**
 * Add OMOP SQL Sets to be queried in Leaf.
 */
INSERT INTO LeafDB.app.ConceptSqlSet (SqlSetFrom, IsEncounterBased, IsEventBased, SqlFieldDate, Created, CreatedBy, Updated, UpdatedBy)
SELECT *
FROM (VALUES ('omop.cdm_deid_std.person',               @no,  @no, NULL,                               GETDATE(), @user, GETDATE(), @user),
             ('omop.cdm_deid_std.visit_occurrence',     @yes, @no, '@.visit_start_datetime',           GETDATE(), @user, GETDATE(), @user),
             -- TODO: Change this to omop.cdm_deid_std.condition_occurrence when it is ready
             ('rpt.test_omop_conditions.condition_occurrence', @yes, @no, '@.condition_start_datetime',       GETDATE(), @user, GETDATE(), @user),
             ('omop.cdm_deid_std.death',                @yes, @no, '@.death_datetime',                 GETDATE(), @user, GETDATE(), @user),
             ('omop.cdm_deid_std.device_exposure',      @yes, @no, '@.device_exposure_start_datetime', GETDATE(), @user, GETDATE(), @user),
             ('omop.cdm_deid_std.drug_exposure',        @yes, @no, '@.drug_exposure_start_datetime',   GETDATE(), @user, GETDATE(), @user),
             ('omop.cdm_deid_std.measurement',          @yes, @no, '@.measurement_datetime',           GETDATE(), @user, GETDATE(), @user),
             ('omop.cdm_deid_std.observation',          @yes, @no, '@.observation_datetime',           GETDATE(), @user, GETDATE(), @user),
             ('omop.cdm_deid_std.procedure_occurrence', @yes, @no, '@.procedure_datetime',             GETDATE(), @user, GETDATE(), @user)
     ) AS X(col1,col2,col3,col4,col5,col6,col7,col8);

/*
Replace all SqlSetFrom tables with sub-queries that transform the person_id into NVARCHAR, which
is needed because they're stored as BINARY(32) in omop.cdm_deid_std; remove these if the person_id
type reverts to an int (or to a bigint and Leaf can support bigints).
*/
UPDATE LeafDB.app.ConceptSqlSet
SET SqlSetFrom = '(SELECT [person_id] = CONVERT(NVARCHAR(50), [person_id]),
                          [gender_concept_id],
                          [year_of_birth],
                          [month_of_birth],
                          [day_of_birth],
                          [birth_datetime],
                          [race_concept_id],
                          [ethnicity_concept_id],
                          [location_id],
                          [provider_id],
                          [care_site_id],
                          [person_source_value],
                          [gender_source_value],
                          [gender_source_concept_id],
                          [race_source_value],
                          [race_source_concept_id],
                          [ethnicity_source_value],
                          [ethnicity_source_concept_id]
                   FROM omop.cdm_deid_std.person)'
WHERE SqlSetFrom LIKE '%person';

UPDATE LeafDB.app.ConceptSqlSet
SET SqlSetFrom = '(SELECT [visit_occurrence_id],
                          [person_id] = CONVERT(NVARCHAR(50), [person_id]),
                          [visit_concept_id],
                          [visit_start_date],
                          [visit_start_datetime],
                          [visit_end_date],
                          [visit_end_datetime],
                          [visit_type_concept_id],
                          [provider_id],
                          [care_site_id],
                          [visit_source_value],
                          [visit_source_concept_id],
                          [admitting_source_concept_id],
                          [admitting_source_value],
                          [discharge_to_concept_id],
                          [discharge_to_source_value],
                          [preceding_visit_occurrence_id]
                   FROM omop.cdm_deid_std.visit_occurrence)'
WHERE SqlSetFrom LIKE '%visit_occurrence';

/*
TODO: Use this when condition_occurrence above can be reverted to use omop.cdm_deid_std.condition_occurrence,
which can be done when it contains omop concepts in condition_occurrence_id and
omop.cdm_deid_std.concept_relationship contains Epic diagnosis to SNOMED codes.
UPDATE LeafDB.app.ConceptSqlSet
SET SqlSetFrom = '(SELECT [condition_occurrence_id],
                          [person_id] = CONVERT(NVARCHAR(50), [person_id]),
                          [condition_concept_id],
                          [condition_start_date],
                          [condition_start_datetime],
                          [condition_end_date],
                          [condition_end_datetime],
                          [condition_type_concept_id],
                          [stop_reason],
                          [provider_id],
                          [visit_occurrence_id],
                          [visit_detail_id],
                          [condition_source_value],
                          [condition_source_concept_id],
                          [condition_status_source_value],
                          [condition_status_concept_id]
                   FROM omop.cdm_deid_std.condition_occurrence)'
WHERE SqlSetFrom LIKE '%condition_occurrence';
*/

UPDATE LeafDB.app.ConceptSqlSet
SET SqlSetFrom = '(SELECT [person_id] = CONVERT(NVARCHAR(50), [person_id]),
                          [death_type_concept_id],
                          [death_type_concept_code],
                          [death_type_concept_name],
                          [visit_occurrence_id],
                          [cause_concept_id],
                          [cause_concept_code],
                          [cause_concept_name],
                          [cause_source_concept_id],
                          [cause_source_concept_code],
                          [cause_source_concept_name],
                          [cause_source_value],
                          [death_date],
                          [death_datetime]
                   FROM omop.cdm_deid_std.death)'
WHERE SqlSetFrom LIKE '%death';

UPDATE LeafDB.app.ConceptSqlSet
SET SqlSetFrom = '(SELECT [device_exposure_id],
                          [device_type_concept_id],
                          [device_type_concept_code],
                          [device_type_concept_name],
                          [visit_occurrence_id],
                          [visit_detail_id],
                          [person_id] = CONVERT(NVARCHAR(50), [person_id]),
                          [provider_id],
                          [device_concept_id],
                          [device_concept_code],
                          [device_concept_name],
                          [device_source_concept_id],
                          [device_source_concept_code],
                          [device_source_concept_name],
                          [device_source_value],
                          [unique_device_id],
                          [device_exposure_start_date],
                          [device_exposure_start_datetime],
                          [device_exposure_end_date],
                          [device_exposure_end_datetime],
                          [quantity]
                   FROM omop.cdm_deid_std.device_exposure)'
WHERE SqlSetFrom LIKE '%device_exposure';

UPDATE LeafDB.app.ConceptSqlSet
SET SqlSetFrom = '(SELECT [drug_exposure_id],
                          [person_id] = CONVERT(NVARCHAR(50), [person_id]),
                          [drug_concept_id],
                          [drug_exposure_start_date],
                          [drug_exposure_start_datetime],
                          [drug_exposure_end_date],
                          [drug_exposure_end_datetime],
                          [verbatim_end_date],
                          [drug_type_concept_id],
                          [stop_reason],
                          [refills],
                          [quantity],
                          [days_supply],
                          [sig],
                          [route_concept_id],
                          [lot_number],
                          [provider_id],
                          [visit_occurrence_id],
                          [visit_detail_id],
                          [drug_source_value],
                          [drug_source_concept_id],
                          [route_source_value],
                          [dose_unit_source_value]
                   FROM omop.cdm_deid_std.drug_exposure)'
WHERE SqlSetFrom LIKE '%drug_exposure';

UPDATE LeafDB.app.ConceptSqlSet
SET SqlSetFrom = '(SELECT [measurement_id],
                          [person_id] = CONVERT(NVARCHAR(50), [person_id]),
                          [measurement_concept_id],
                          [measurement_date],
                          [measurement_datetime],
                          [measurement_time],
                          [measurement_type_concept_id],
                          [operator_concept_id],
                          [value_as_number],
                          [value_as_concept_id],
                          [unit_concept_id],
                          [range_low],
                          [range_high],
                          [provider_id],
                          [visit_occurrence_id],
                          [visit_detail_id],
                          [measurement_source_value],
                          [measurement_source_concept_id],
                          [unit_source_value],
                          [value_source_value]
                   FROM omop.cdm_deid_std.measurement)'
WHERE SqlSetFrom LIKE '%measurement';

UPDATE LeafDB.app.ConceptSqlSet
SET SqlSetFrom = '(SELECT [observation_id],
                          [person_id] = CONVERT(NVARCHAR(50), [person_id]),
                          [observation_concept_id],
                          [observation_date],
                          [observation_datetime],
                          [observation_type_concept_id],
                          [value_as_number],
                          [value_as_string],
                          [value_as_concept_id],
                          [qualifier_concept_id],
                          [unit_concept_id],
                          [provider_id],
                          [visit_occurrence_id],
                          [visit_detail_id],
                          [observation_source_value],
                          [observation_source_concept_id],
                          [unit_source_value],
                          [qualifier_source_value]
                   FROM omop.cdm_deid_std.observation)'
WHERE SqlSetFrom LIKE '%observation';

UPDATE LeafDB.app.ConceptSqlSet
SET SqlSetFrom = '(SELECT [procedure_occurrence_id],
                          [person_id] = CONVERT(NVARCHAR(50), [person_id]),
                          [procedure_concept_id],
                          [procedure_date],
                          [procedure_datetime],
                          [procedure_type_concept_id],
                          [modifier_concept_id],
                          [quantity],
                          [provider_id],
                          [visit_occurrence_id],
                          [visit_detail_id],
                          [procedure_source_value],
                          [procedure_source_concept_id],
                          [modifier_source_value]
                  FROM omop.cdm_deid_std.procedure_occurrence)'
WHERE SqlSetFrom LIKE '%procedure_occurrence';
