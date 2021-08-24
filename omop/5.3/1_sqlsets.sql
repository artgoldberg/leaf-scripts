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
FROM (VALUES ('omop.cdm_deid.person',               @no,  @no,  NULL,                              GETDATE(), @user, GETDATE(), @user),
             ('omop.cdm_deid.visit_occurrence',     @yes, @no, '@.visit_start_datetime',           GETDATE(), @user, GETDATE(), @user),
             ('rpt.test_omop_conditions.condition_occurrence', @yes, @no, '@.condition_start_datetime',       GETDATE(), @user, GETDATE(), @user),
             ('omop.cdm_deid.death',                @yes, @no, '@.death_datetime',                 GETDATE(), @user, GETDATE(), @user),
             ('omop.cdm_deid.device_exposure',      @yes, @no, '@.device_exposure_start_datetime', GETDATE(), @user, GETDATE(), @user),
             ('omop.cdm_deid.drug_exposure',        @yes, @no, '@.drug_exposure_start_datetime',   GETDATE(), @user, GETDATE(), @user),
             ('omop.cdm_deid.measurement',          @yes, @no, '@.measurement_datetime',           GETDATE(), @user, GETDATE(), @user),
             ('omop.cdm_deid.observation',          @yes, @no, '@.observation_datetime',           GETDATE(), @user, GETDATE(), @user),
             ('omop.cdm_deid.procedure_occurrence', @yes, @no, '@.procedure_datetime',             GETDATE(), @user, GETDATE(), @user)
     ) AS X(col1,col2,col3,col4,col5,col6,col7,col8)