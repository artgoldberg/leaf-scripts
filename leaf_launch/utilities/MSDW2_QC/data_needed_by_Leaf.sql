/*
 * Duplicate code: CTEs for gender, ethnicity, race and vital status from the Leaf 2_demographics.sql script
 * and for vital signs from 5_vitals.sql.
 * Author: Arthur.Goldberg@mssm.edu
 */

USE omop;

-- Gender, assuming omop codes
SELECT concept.concept_name,
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
SELECT OMOP_concept.concept_name,
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

-- Ethnicity
SELECT concept.concept_name,
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
SELECT concept.concept_name,
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
-- This returns "Deceased	12,751,902,915" because death.person_id and/or person.person_id contains many duplicates
/*
Comment out, as runs very slowly.
SELECT 'Deceased', COUNT_BIG(*)
FROM cdm_deid_std.death death,
     cdm_deid_std.person person
WHERE death.person_id = person.person_id;

SELECT 'Deceased', COUNT_BIG(*)
-- whereas this returns "Deceased	0".
FROM cdm_std.death death,
     cdm_std.person person
WHERE death.person_id = person.person_id;
*/

-- The problem is that all the person_ids in death are the same.
-- This returns one row: "                                	31065":
SELECT person_id, COUNT(*)
FROM cdm_deid_std.death
GROUP BY person_id

-- Vitals

/*
Was
DECLARE @temp          INT = 3020891
DECLARE @heartRate     INT = 3027018
DECLARE @respRate      INT = 3024171
DECLARE @bpDiast       INT = 3012888
DECLARE @bpSyst        INT = 3004249
DECLARE @weight        INT = 3025315
DECLARE @height        INT = 3036277
DECLARE @pulse         INT = 3027018
DECLARE @bmi           INT = 40540383
Dropping pulse, which isn't in concept, and bmi which has passed its valid end date
*/

DECLARE @temp  INT = (SELECT concept_id
                             FROM cdm_deid_std.concept
                             WHERE concept_name = 'Body temperature'
                                   AND standard_concept = 'S'
                                   AND concept_class_id = 'Clinical Observation'
                                   AND vocabulary_id = 'LOINC')
PRINT '@temp  = ' + CAST(@temp  AS VARCHAR)

DECLARE @heartRate INT = (SELECT concept_id
                                 FROM cdm_deid_std.concept
                                 WHERE concept_name = 'Heart rate'
                                       AND standard_concept = 'S'
                                       AND concept_class_id = 'Clinical Observation'
                                       AND vocabulary_id = 'LOINC')
PRINT '@heartRate = ' + CAST(@heartRate AS VARCHAR)

DECLARE @respRate INT = (SELECT concept_id
                                FROM cdm_deid_std.concept
                                WHERE concept_name = 'Respiratory rate'
                                      AND standard_concept = 'S'
                                      AND concept_class_id = 'Clinical Observation'
                                      AND vocabulary_id = 'LOINC')
PRINT '@respRate = ' + CAST(@respRate AS VARCHAR)

DECLARE @bpDiast INT = (SELECT concept_id
                               FROM cdm_deid_std.concept
                               WHERE concept_name = 'Diastolic blood pressure'
                                     AND standard_concept = 'S'
                                     AND concept_class_id = 'Clinical Observation'
                                     AND vocabulary_id = 'LOINC')
PRINT '@bpDiast = ' + CAST(@bpDiast AS VARCHAR)

DECLARE @bpSyst INT = (SELECT concept_id
                              FROM cdm_deid_std.concept
                              WHERE concept_name = 'Systolic blood pressure'
                                    AND standard_concept = 'S'
                                    AND concept_class_id = 'Clinical Observation'
                                    AND vocabulary_id = 'LOINC')
PRINT '@bpSyst = ' + CAST(@bpSyst AS VARCHAR)

DECLARE @weight INT = (SELECT concept_id
                              FROM cdm_deid_std.concept
                              WHERE concept_name = 'Body weight'
                                    AND standard_concept = 'S'
                                    AND concept_class_id = 'Clinical Observation'
                                    AND vocabulary_id = 'LOINC')
PRINT '@weight = ' + CAST(@weight AS VARCHAR)

DECLARE @height INT = (SELECT concept_id
                              FROM cdm_deid_std.concept
                              WHERE concept_name = 'Body height'
                                    AND standard_concept = 'S'
                                    AND concept_class_id = 'Clinical Observation'
                                    AND vocabulary_id = 'LOINC')
PRINT '@height = ' + CAST(@height AS VARCHAR)

SELECT concept.concept_name,
       concept.concept_id,
       [count] = COUNT(DISTINCT person_id)
FROM cdm_deid_std.measurement
     LEFT JOIN cdm_deid_std.concept AS concept
        ON measurement_concept_id = concept.concept_id
WHERE measurement_concept_id IN (@bpSyst, @bpDiast, @height, @weight, @heartRate, @temp, @respRate)
GROUP BY concept.concept_name, concept.concept_id;

-- Visits
SELECT concept.concept_name,
       concept.concept_id,
       [count] = COUNT(DISTINCT person_id),
       'cdm_deid_std visits'
FROM cdm_deid_std.visit_occurrence AS visit_occurrence INNER JOIN cdm_deid_std.concept AS concept
     ON visit_occurrence.visit_concept_id = concept.concept_id
WHERE visit_occurrence.visit_concept_id != 0
GROUP BY concept.concept_name, concept.concept_id;

-- Visits
SELECT concept.concept_name,
       concept.concept_id,
       [count] = COUNT(DISTINCT person_id),
       'cdm_deid_std visits'
FROM cdm_deid_std.visit_occurrence AS visit_occurrence INNER JOIN cdm_deid_std.concept AS concept
     ON visit_occurrence.visit_concept_id = concept.concept_id
WHERE visit_occurrence.visit_concept_id != 0
GROUP BY concept.concept_name, concept.concept_id;

-- person.person_id values
-- These two queries should return the same values, but as of 2021-08-24 they return
-- 13,247,329 and 72,767, respectively

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
