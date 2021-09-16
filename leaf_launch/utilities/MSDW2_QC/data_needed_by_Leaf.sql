/*
 * Mimic the CTEs for gender, ethnicity, race and vital status from the Leaf 2_demographics.sql script
 * and for vital signs from 5_vitals.sql.
 * Author: Arthur.Goldberg@mssm.edu
 */

-- Don't acquire READ locks
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

USE omop;

-- Gender, assuming omop codes
SELECT 'cdm_deid_std',
       concept.concept_name,
       concept.concept_id,
       [count] = COUNT(DISTINCT person_id),
       concept_id_string = CONVERT(NVARCHAR(50), concept.concept_id)
FROM cdm_deid_std.person AS person
     INNER JOIN cdm_deid_std.concept AS concept
     ON person.gender_concept_id = concept.concept_id
WHERE person.gender_concept_id <> 0
GROUP BY concept.concept_name, concept.concept_id
ORDER BY concept.concept_name;

-- Gender, assuming Epic codes
/*
SELECT 'cdm_deid_std',
       OMOP_concept.concept_name,
       OMOP_concept.concept_id,
       [count] = COUNT(DISTINCT person_id),
       concept_id_string = CONVERT(NVARCHAR(50), OMOP_concept.concept_id)
FROM cdm_deid_std.person AS person
     INNER JOIN cdm_deid_std.concept AS Epic_concept
     ON person.gender_concept_id = Epic_concept.concept_id,
     cdm_deid_std.concept AS OMOP_concept,
     cdm_deid_std.concept_relationship concept_relationship
WHERE person.gender_concept_id <> 0
      AND Epic_concept.vocabulary_id LIKE 'EPIC%'
      AND Epic_concept.concept_id = concept_relationship.concept_id_1
      AND concept_relationship.relationship_id = 'Maps to'
      AND concept_relationship.concept_id_2 = OMOP_concept.concept_id
      AND OMOP_concept.vocabulary_id = 'Gender'
GROUP BY OMOP_concept.concept_name, OMOP_concept.concept_id
ORDER BY OMOP_concept.concept_name;
*/

-- Ethnicity
SELECT 'cdm_deid_std',
       concept.concept_name,
       concept.concept_id,
       [count] = COUNT(DISTINCT person_id),
       concept_id_string = CONVERT(NVARCHAR(50), concept.concept_id)
FROM cdm_deid_std.person AS person
     INNER JOIN cdm_deid_std.concept AS concept
     ON person.ethnicity_concept_id = concept.concept_id
WHERE person.ethnicity_concept_id <> 0
GROUP BY concept.concept_name, concept.concept_id
ORDER BY concept.concept_name;

-- Race
SELECT 'cdm_deid_std',
       concept.concept_name,
       concept.concept_id,
       [count] = COUNT(DISTINCT person_id),
       concept_id_string = CONVERT(NVARCHAR(50), concept.concept_id)
FROM cdm_deid_std.person AS person
     INNER JOIN cdm_deid_std.concept AS concept
     ON person.race_concept_id = concept.concept_id
WHERE person.race_concept_id <> 0
GROUP BY concept.concept_name, concept.concept_id
ORDER BY concept.concept_name;

-- Vital status (alive or dead)
-- This returned "Deceased	12,751,902,915" because death.person_id and/or person.person_id contains many duplicates
-- Comment out, as runs very slowly.
-- Fixed!
SELECT COUNT_BIG(*) AS 'Deceased in cdm'
FROM cdm.death death,
     cdm.person person
WHERE death.person_id = person.person_id;

-- whereas this returned "Deceased	0".
SELECT COUNT_BIG(*) AS 'Deceased in cdm_deid_std'
FROM cdm_deid_std.death death,
     cdm_deid_std.person person
WHERE death.person_id = person.person_id;

-- The problem was that all the person_ids in death are the same.
-- This returns one row: "                                	31065":
-- FIXED
SELECT person_id, COUNT(*)
FROM cdm_deid_std.death
GROUP BY person_id

-- Vitals
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
                              vital_units NVARCHAR(MAX) NOT NULL)
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
             (@peds_systolic_bp,    @percent)) AS X(col1, col2)

SELECT 'vitals in cdm_deid',
       concept.concept_name,
       concept.concept_id,
       [count] = COUNT(DISTINCT person_id),
       vital_units
FROM #vitals_w_units,
     cdm_deid.measurement
     LEFT JOIN cdm_deid.concept AS concept
        ON measurement_concept_id = concept.concept_id
WHERE measurement_concept_id IN (SELECT vital_concept_id
                                 FROM #vitals_w_units)
      AND vital_concept_id = concept.concept_id
GROUP BY concept.concept_name, concept.concept_id, vital_units;

-- All visits
-- cdm visits
SELECT 'cdm visits' AS 'Schema',
       concept.concept_name,
       concept.concept_id,
       [count] = COUNT(DISTINCT person_id)
FROM cdm.visit_occurrence AS visit_occurrence INNER JOIN cdm.concept AS concept
     ON visit_occurrence.visit_concept_id = concept.concept_id
WHERE visit_occurrence.visit_concept_id != 0
GROUP BY concept.concept_name, concept.concept_id

UNION ALL

-- cdm_deid visits
SELECT 'cdm_deid visits' AS 'Schema',
       concept.concept_name,
       concept.concept_id,
       [count] = COUNT(DISTINCT person_id)
FROM cdm_deid.visit_occurrence AS visit_occurrence INNER JOIN cdm_deid.concept AS concept
     ON visit_occurrence.visit_concept_id = concept.concept_id
WHERE visit_occurrence.visit_concept_id != 0
GROUP BY concept.concept_name, concept.concept_id

UNION ALL

-- cdm_deid_std visits
SELECT 'cdm_deid_std visits' AS 'Schema',
       concept.concept_name,
       concept.concept_id,
       [count] = COUNT(DISTINCT person_id)
FROM cdm_deid_std.visit_occurrence AS visit_occurrence INNER JOIN cdm_deid_std.concept AS concept
     ON visit_occurrence.visit_concept_id = concept.concept_id
WHERE visit_occurrence.visit_concept_id != 0
GROUP BY concept.concept_name, concept.concept_id;

-- person.person_id values
-- These two queries should return the same values, but as of 2021-08-24 they return
-- 13,247,329 and 72,767, respectively
-- Fixed!
-- TODO: PRINT the result
SELECT COUNT(person_id)
FROM cdm_deid_std.person;

SELECT COUNT(DISTINCT person_id)
FROM cdm_deid_std.person;

-- Procedure codes
SELECT 'cdm' AS 'Schema',
       'Procedures' AS 'Code',
       COUNT(*) AS 'Count',
       procedure_source_concept_id,
       '',
       '',
       procedure_source_value
FROM cdm.procedure_occurrence
WHERE procedure_source_concept_id IS NOT NULL
      AND 0 < procedure_source_concept_id
      AND procedure_source_value IS NOT NULL
GROUP BY procedure_source_concept_id, procedure_source_value;

SELECT 'cdm_deid_std' AS 'Schema',
       'Procedures' AS 'Code',
       COUNT(*) AS 'Count',
       procedure_source_concept_id,
       procedure_source_concept_code,
       procedure_source_concept_name,
       procedure_source_value
FROM cdm_deid_std.procedure_occurrence
WHERE procedure_source_concept_id IS NOT NULL
      AND 0 < procedure_source_concept_id
      AND procedure_source_concept_code IS NOT NULL
      AND procedure_source_concept_name IS NOT NULL
      AND procedure_source_value IS NOT NULL
GROUP BY procedure_source_concept_id,
         procedure_source_concept_code,
         procedure_source_concept_name,
         procedure_source_value
