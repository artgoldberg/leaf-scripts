/*
 * Duplicate code: CTEs for gender, ethnicity and race from the Leaf 2_demographics.sql script
 * Author: Arthur.Goldberg@mssm.edu
 */

-- Gender, assuming omop codes
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

-- Gender, assuming Epic codes
SELECT OMOP_concept.concept_name,
       OMOP_concept.concept_id,
       [count] = COUNT(DISTINCT person_id),
       concept_id_string = CONVERT(NVARCHAR(50), OMOP_concept.concept_id)
FROM omop.cdm.person AS person
     INNER JOIN omop.cdm.concept AS Epic_concept
     ON person.gender_concept_id = Epic_concept.concept_id,
     omop.cdm.concept AS OMOP_concept,
     omop.cdm.concept_relationship concept_relationship
WHERE person.gender_concept_id <> 0
      AND Epic_concept.vocabulary_id LIKE 'EPIC%'
      AND Epic_concept.concept_id = concept_relationship.concept_id_1
      AND concept_relationship.relationship_id = 'Maps to'
      AND concept_relationship.concept_id_2 = OMOP_concept.concept_id
      AND OMOP_concept.vocabulary_id = 'Gender'
GROUP BY OMOP_concept.concept_name, OMOP_concept.concept_id
ORDER BY OMOP_concept.concept_name

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
