/*
 * Duplicate code: CTEs for gender, ethnicity and race from the Leaf 2_demographics.sql script
 * Author: Arthur.Goldberg@mssm.edu
 */

-- Gender
SELECT concept.concept_name,
       concept.concept_id,
       [count] = COUNT(DISTINCT person_id),
       concept_id_string = CONVERT(NVARCHAR(50), concept.concept_id)
FROM omop.cdm.person AS person
     INNER JOIN omop.cdm.concept AS concept
     ON person.gender_concept_id = concept.concept_id
WHERE person.gender_concept_id <> 0
GROUP BY concept.concept_name, concept.concept_id
ORDER BY concept.concept_name

-- Ethnicity
SELECT concept.concept_name,
       concept.concept_id,
       [count] = COUNT(DISTINCT person_id),
       concept_id_string = CONVERT(NVARCHAR(50), concept.concept_id)
FROM omop.cdm.person AS person
     INNER JOIN omop.cdm.concept AS concept
     ON person.ethnicity_concept_id = concept.concept_id
WHERE person.ethnicity_concept_id <> 0
GROUP BY concept.concept_name, concept.concept_id
ORDER BY concept.concept_name

-- Race
SELECT concept.concept_name,
       concept.concept_id,
       [count] = COUNT(DISTINCT person_id),
       concept_id_string = CONVERT(NVARCHAR(50), concept.concept_id)
FROM omop.cdm.person AS person
     INNER JOIN omop.cdm.concept AS concept
     ON person.race_concept_id = concept.concept_id
WHERE person.race_concept_id <> 0
GROUP BY concept.concept_name, concept.concept_id
ORDER BY concept.concept_name
