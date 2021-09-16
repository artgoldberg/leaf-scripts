/**
 * Leaf OMOP 5.3 bootstrap script.
 * Vitals
 */

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

BEGIN

    DECLARE @yes BIT = 1
    DECLARE @no  BIT = 0

    DECLARE @sqlset_person               INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom LIKE '%cdm_deid.person%')
    DECLARE @sqlset_visit_occurrence     INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom LIKE '%cdm_deid.visit_occurrence%')
    DECLARE @sqlset_condition_occurrence INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                -- TODO: Change this to '%[condition_occurrence]%' when it is ready
                                                WHERE SqlSetFrom LIKE '%rpt.test_omop_conditions.condition_occurrence_deid%')
    DECLARE @sqlset_death                INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom LIKE '%cdm_deid.death%')
    DECLARE @sqlset_device_exposure      INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom LIKE '%cdm_deid.device_exposure%')
    DECLARE @sqlset_drug_exposure        INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom LIKE '%cdm_deid.drug_exposure%')
    DECLARE @sqlset_measurement          INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom LIKE '%cdm_deid.measurement%')
    DECLARE @sqlset_observation          INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom LIKE '%cdm_deid.observation%')
    DECLARE @sqlset_procedure_occurrence INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom LIKE '%cdm_deid.procedure_occurrence%')

    DECLARE @vitals_root   NVARCHAR(50) = 'vitals'

    USE omop;
    DECLARE @temp INT = (SELECT concept_id
                         FROM cdm_deid.concept
                         WHERE concept_name = 'Body temperature'
                               AND standard_concept = 'S'
                               AND concept_class_id = 'Clinical Observation'
                               AND vocabulary_id = 'LOINC')

    DECLARE @respRate INT = (SELECT concept_id
                             FROM cdm_deid.concept
                             WHERE concept_name = 'Respiratory rate'
                                   AND standard_concept = 'S'
                                   AND concept_class_id = 'Clinical Observation'
                                   AND vocabulary_id = 'LOINC')

    DECLARE @bpDiast INT = (SELECT concept_id
                            FROM cdm_deid.concept
                            WHERE concept_name = 'Diastolic blood pressure'
                                  AND standard_concept = 'S'
                                  AND concept_class_id = 'Clinical Observation'
                                  AND vocabulary_id = 'LOINC')

    DECLARE @bpSyst INT = (SELECT concept_id
                           FROM cdm_deid.concept
                           WHERE concept_name = 'Systolic blood pressure'
                                 AND standard_concept = 'S'
                                 AND concept_class_id = 'Clinical Observation'
                                 AND vocabulary_id = 'LOINC')

    DECLARE @weight INT = (SELECT concept_id
                           FROM cdm_deid.concept
                           WHERE concept_name = 'Body weight'
                                 AND standard_concept = 'S'
                                 AND concept_class_id = 'Clinical Observation'
                                 AND vocabulary_id = 'LOINC')

    DECLARE @height INT = (SELECT concept_id
                           FROM cdm_deid.concept
                           WHERE concept_name = 'Body height'
                                 AND standard_concept = 'S'
                                 AND concept_class_id = 'Clinical Observation'
                                 AND vocabulary_id = 'LOINC')

    DECLARE @coma_score INT = (SELECT concept_id
                               FROM cdm_deid.concept
                               WHERE concept_name = 'Glasgow coma score total'
                                     AND standard_concept = 'S'
                                     AND concept_class_id = 'Clinical Observation'
                                     AND vocabulary_id = 'LOINC')

    DECLARE @O2_sat INT = (SELECT concept_id
                           FROM cdm_deid.concept
                           WHERE concept_name = 'Oxygen saturation in Blood'
                                 AND standard_concept = 'S'
                                 AND concept_class_id = 'Clinical Observation'
                                 AND vocabulary_id = 'LOINC')

    DECLARE @fetal_head_circum INT = (SELECT concept_id
                                      FROM cdm_deid.concept
                                      WHERE concept_name = 'Fetal Head Circumference US'
                                            AND standard_concept = 'S'
                                            AND concept_class_id = 'Clinical Observation'
                                            AND vocabulary_id = 'LOINC')

    DECLARE @pain_severity INT = (SELECT concept_id
                                  FROM cdm_deid.concept
                                  WHERE concept_name = 'Pain severity Wong-Baker FACES pain rating scale'
                                        AND standard_concept = 'S'
                                        AND concept_class_id = 'Clinical Observation'
                                        AND vocabulary_id = 'LOINC')

    DECLARE @bmi INT = (SELECT concept_id
                        FROM cdm_deid.concept
                        WHERE concept_name = 'Body mass index (bmi) [Ratio]'
                              AND standard_concept = 'S'
                              AND concept_class_id = 'Clinical Observation'
                              AND vocabulary_id = 'LOINC')

    DECLARE @pulse INT = (SELECT concept_id
                          FROM cdm_deid.concept
                          WHERE concept_name = 'Pulse rate'
                                AND standard_concept = 'S'
                                AND concept_class_id = 'Observable Entity'
                                AND vocabulary_id = 'SNOMED')

    DECLARE @SOFA_score INT = (SELECT concept_id
                               FROM cdm_deid.concept
                               WHERE concept_name = 'SOFA (Sequential Organ Failure Assessment) score'
                                     AND standard_concept = 'S'
                                     AND concept_class_id = 'Observable Entity'
                                     AND vocabulary_id = 'SNOMED')

    DECLARE @peds_diastolic_bp INT = (SELECT concept_id
                                      FROM cdm_deid.concept
                                      WHERE concept_name = 'Pediatric diastolic blood pressure percentile [Per age, sex and height]'
                                            AND standard_concept = 'S'
                                            AND concept_class_id = 'Survey'
                                            AND vocabulary_id = 'LOINC')

    DECLARE @peds_systolic_bp INT = (SELECT concept_id
                                     FROM cdm_deid.concept
                                     WHERE concept_name = 'Pediatric systolic blood pressure percentile [Per age, sex and height]'
                                           AND standard_concept = 'S'
                                           AND concept_class_id = 'Survey'
                                           AND vocabulary_id = 'LOINC')

    DECLARE @per_minute NVARCHAR(50) = (SELECT concept_name
                                        FROM cdm_deid.concept
                                        WHERE concept_name = 'counts per minute'
                                              AND standard_concept = 'S'
                                              AND concept_class_id = 'Unit'
                                              AND vocabulary_id = 'UCUM')

    DECLARE @percent NVARCHAR(50) = (SELECT concept_name
                                     FROM cdm_deid.concept
                                     WHERE concept_name = 'percent'
                                           AND standard_concept = 'S'
                                           AND concept_class_id = 'Unit'
                                           AND vocabulary_id = 'UCUM')

    DECLARE @pressure_mm_hg NVARCHAR(50) = (SELECT concept_name
                                            FROM cdm_deid.concept
                                            WHERE concept_name = 'millimeter mercury column'
                                                  AND standard_concept = 'S'
                                                  AND concept_class_id = 'Unit'
                                                  AND vocabulary_id = 'UCUM')

    DECLARE @degree_F NVARCHAR(50) = (SELECT concept_name
                                      FROM cdm_deid.concept
                                      WHERE concept_name = 'degree Fahrenheit'
                                            AND standard_concept = 'S'
                                            AND concept_class_id = 'Unit'
                                            AND vocabulary_id = 'UCUM')

    DECLARE @inch NVARCHAR(50) = (SELECT concept_name
                                  FROM cdm_deid.concept
                                  WHERE concept_name = 'inch (US)'
                                        AND standard_concept = 'S'
                                        AND concept_class_id = 'Unit'
                                        AND vocabulary_id = 'UCUM')

    DECLARE @ounce NVARCHAR(50) = (SELECT concept_name
                                   FROM cdm_deid.concept
                                   WHERE concept_name = 'ounce (avoirdupois)'
                                         AND standard_concept = 'S'
                                         AND concept_class_id = 'Unit'
                                         AND vocabulary_id = 'UCUM')

    DECLARE @kg_per_m2 NVARCHAR(50) = (SELECT concept_name
                                       FROM cdm_deid.concept
                                       WHERE concept_name = 'kilogram per square meter'
                                             AND standard_concept = 'S'
                                             AND concept_class_id = 'Unit'
                                             AND vocabulary_id = 'UCUM')

    DECLARE @score NVARCHAR(50) = (SELECT concept_name
                                   FROM cdm_deid.concept
                                   WHERE concept_name = 'score'
                                         AND standard_concept = 'S'
                                         AND concept_class_id = 'Unit'
                                         AND vocabulary_id = 'UCUM')

    DROP TABLE IF EXISTS #vitals_w_units
    CREATE TABLE #vitals_w_units (vital_concept_id INT NOT NULL PRIMARY KEY,
                                  vital_units NVARCHAR(50) NOT NULL)
    INSERT INTO #vitals_w_units
    SELECT *
    FROM (VALUES (@temp,                @degree_F),
                 (@respRate,            @per_minute),
                 (@bpDiast,             @pressure_mm_hg),
                 (@bpSyst,              @pressure_mm_hg),
                 (@weight,              @ounce),
                 (@height,              @inch),
                 (@coma_score,          @score),
                 (@O2_sat,              @percent),
                 (@fetal_head_circum,   @inch),
                 (@pain_severity,       @score),
                 (@bmi,                 @kg_per_m2),
                 (@pulse,               @per_minute),
                 (@SOFA_score,          @score),
                 (@peds_diastolic_bp,   @percent),
                 (@peds_systolic_bp,    @percent)) AS X(col1, col2);

    ; WITH vitals AS
    (
        SELECT concept.concept_name, concept.concept_id, cnt = COUNT(DISTINCT person_id),
               concept_id_string = CONVERT(NVARCHAR(50), concept.concept_id), vital_units
        FROM #vitals_w_units,
             omop.cdm_deid.measurement AS measurement
			 LEFT JOIN omop.cdm_deid.concept AS concept
				  ON measurement.measurement_concept_id = concept.concept_id
        WHERE measurement.measurement_concept_id IN (SELECT vital_concept_id
                                                     FROM #vitals_w_units)
              AND vital_concept_id = concept.concept_id
        GROUP BY concept.concept_name, concept.concept_id, vital_units
    )

    /* INSERT */
    INSERT INTO LeafDB.app.Concept (ExternalId, ExternalParentId, [IsNumeric], IsParent, IsRoot, SqlSetId,
                                    SqlSetWhere, SqlFieldNumeric, UiDisplayName, UiDisplayText, UiDisplayUnits,
                                    UiNumericDefaultText, UiDisplayPatientCount)

    /* Root */
    SELECT ExternalId            = @vitals_root
         , ExternalParentId      = NULL
         , [IsNumeric]           = @no
         , IsParent              = @yes
         , IsRoot                = @yes
         , SqlSetId              = @sqlset_measurement
         , SqlSetWhere           = NULL
         , SqlFieldNumeric       = NULL
         , UiDisplayName         = 'Vitals'
         , UiDisplayText         = 'Had vitals measured'
         , UiDisplayUnits        = NULL
         , UiNumericDefaultText  = NULL
         , UiDisplayPatientCount = (SELECT COUNT(DISTINCT person_id)
                                    FROM omop.cdm_deid.measurement
                                    WHERE measurement_concept_id IN (SELECT vital_concept_id
                                                                     FROM #vitals_w_units))

    UNION ALL

    /* Vitals */
    SELECT ExternalId            = 'vitals:' + _vitals.concept_id_string
         , ExternalParentId      = @vitals_root
         , [IsNumeric]           = @yes
         , IsParent              = @no
         , IsRoot                = @no
         , SqlSetId              = @sqlset_measurement
         , SqlSetWhere           = '@.measurement_concept_id = ' + _vitals.concept_id_string
         , SqlFieldNumeric       = '@.value_as_number'
         , UiDisplayName         = _vitals.concept_name
         , UiDisplayText         = 'Had ' + _vitals.concept_name + ' measured'
         , UiDisplayUnits        = _vitals.vital_units
         , UiNumericDefaultText  = 'of any result'
         , UiDisplayPatientCount = _vitals.cnt
    FROM vitals AS _vitals

    /**
    * Set ParentId based on ExternalIds
    */
    UPDATE LeafDB.app.Concept
    SET ParentId = P.Id
    FROM LeafDB.app.Concept AS C
        INNER JOIN (SELECT P.Id, P.ParentId, P.ExternalId
                    FROM LeafDB.app.Concept AS P) AS P
                        ON C.ExternalParentID = P.ExternalID
    WHERE C.ParentId IS NULL

    /**
    * Set RootIds
    */
    ; WITH roots AS
    (
        SELECT
		      RootId            = C.Id
            , RootUiDisplayName = C.UiDisplayName
            , C.IsRoot
            , C.Id
            , C.ParentId
            , C.UiDisplayName
        FROM LeafDB.app.Concept AS C
        WHERE C.IsRoot = 1

        UNION ALL

        SELECT roots.RootId
            , roots.RootUiDisplayName
            , C2.IsRoot
            , C2.Id
            , C2.ParentId
            , C2.UiDisplayName
        FROM roots
            INNER JOIN LeafDB.app.Concept AS C2
                ON C2.ParentId = roots.Id
    )

    UPDATE LeafDB.app.Concept
    SET RootId = roots.RootId
    FROM LeafDB.app.Concept AS C
        INNER JOIN roots
            ON C.Id = roots.Id
    WHERE C.RootId IS NULL

END