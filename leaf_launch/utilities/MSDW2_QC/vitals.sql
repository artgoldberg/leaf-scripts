/**
 * Leaf OMOP 5.3 bootstrap script.
 * Vitals essentials
 */

SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

USE omop;

-- Define concept id variables for vitals, using cdm_deid.concept
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

-- Define string values of units used by vitals, using cdm_deid.concept
-- These queries are deliberately stupid, as they simply query for a concept name value, and then save the name in a variable
-- In doing so, they confirm that the concept with the given name exists
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

-- Create a table that pairs each vital with its units
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

-- Show that all units are in the concepts table, which is redundant with the code above
SELECT concept.concept_name, concept.concept_id,
       concept_id_string = CONVERT(NVARCHAR(50), concept.concept_id), vital_units
FROM #vitals_w_units, omop.cdm_deid.concept AS concept
WHERE vital_concept_id = concept.concept_id;

-- Show that all but 3 (as of 2021-09-29 19:20) vital concept ids are not present in omop.cdm_deid.measurement.measurement_concept_id
SELECT concept.concept_name, concept.concept_id, [count] = COUNT(DISTINCT person_id)
FROM omop.cdm_deid.measurement AS measurement,
     omop.cdm_deid.concept AS concept
WHERE measurement.measurement_concept_id = concept.concept_id
      AND concept.concept_id IN (SELECT vital_concept_id
                                 FROM #vitals_w_units)
GROUP BY concept.concept_name, concept.concept_id
