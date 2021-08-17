/*
 * Create "Epic LRR" code → LOINC mappings
 * Results are new entries in the Leaf_usagi.mapping_import table
 * Author: Arthur.Goldberg@mssm.edu
 */

-- Get Epic LRR name → LOINC mappings from sema4
DECLARE @Epic_LRR_name_to_LOINC TABLE (measurement_concept_id INT PRIMARY KEY,
                                       Epic_LRR_name VARCHAR[-1]),
                                       concept_name
                                       

INSERT INTO @Epic_LRR_name_to_LOINC

SELECT measurement.measurement_concept_id,
       measurement.measurement_source_value Epic_LRR_name,
       concept.concept_name,
       concept.concept_code LOINC_code
FROM sema4.S4_OMOP.measurement measurement,
     sema4.S4_OMOP.concept concept
WHERE concept.vocabulary_id = 'LOINC'
      AND concept.concept_id = measurement.measurement_concept_id
      AND concept.concept_id IS NOT NULL
      AND measurement.measurement_source_value <> 'NOT AVAILABLE'
GROUP BY measurement.measurement_concept_id,
         measurement.measurement_source_value,
         concept.concept_name,
         concept.concept_code

-- This version too slow
-- SELECT measurement.measurement_concept_id,
--        measurement.measurement_source_value Epic_LRR_name,
--        concept.concept_name,
--        concept.vocabulary_id,
--        concept.concept_code,
--        COUNT (*) AS Frequency
-- FROM sema4.S4_OMOP.measurement measurement,
--      sema4.S4_OMOP.concept concept
-- WHERE concept.vocabulary_id = 'LOINC'
--       AND concept.concept_id = measurement.measurement_concept_id
--       AND concept.concept_id IS NOT NULL
-- GROUP BY measurement.measurement_concept_id,
--          measurement.measurement_source_value,
--          concept.concept_name,
--          concept.vocabulary_id,
--          concept.concept_code
-- ORDER BY Frequency DESC
