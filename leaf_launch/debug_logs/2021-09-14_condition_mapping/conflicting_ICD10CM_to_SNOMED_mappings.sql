-- Conflicting ICD10CM to SNOMED mappings in concept_relationship
-- Records in concept_relationship that map a particular ICD10CM concept to multiple SNOMED concepts
DECLARE @cardinality_I10_2_SNOMED_mappings TABLE (ICD10_concept_code NVARCHAR(50) PRIMARY KEY,
                                                  num_SNOMED_concept_codes INT)

INSERT INTO @cardinality_I10_2_SNOMED_mappings
SELECT concept_ICD10.concept_code, COUNT(concept_SNOMED.concept_code)
FROM omop.cdm.concept_relationship concept_relationship,
     omop.cdm.concept concept_ICD10,
     omop.cdm.concept concept_SNOMED
WHERE concept_ICD10.vocabulary_id = 'ICD10CM'
    AND concept_SNOMED.vocabulary_id = 'SNOMED'
    AND concept_relationship.relationship_id = 'Maps to'
    AND concept_ICD10.concept_id = concept_relationship.concept_id_1
    AND concept_SNOMED.concept_id = concept_relationship.concept_id_2
GROUP BY concept_ICD10.concept_code

DECLARE @conflicting_ICD10CM_to_SNOMED_mappings INT =
    (SELECT COUNT(DISTINCT(concept_ICD10.concept_id))
     FROM omop.cdm.concept_relationship concept_relationship,
          omop.cdm.concept concept_ICD10,
          omop.cdm.concept concept_SNOMED,
          @cardinality_I10_2_SNOMED_mappings cardinality_I10_2_SNOMED_mappings
     WHERE concept_ICD10.vocabulary_id = 'ICD10CM'
         AND concept_SNOMED.vocabulary_id = 'SNOMED'
         AND concept_relationship.relationship_id = 'Maps to'
         AND concept_ICD10.concept_id = concept_relationship.concept_id_1
         AND concept_SNOMED.concept_id = concept_relationship.concept_id_2
         AND cardinality_I10_2_SNOMED_mappings.ICD10_concept_code = concept_ICD10.concept_code
         AND 1 < cardinality_I10_2_SNOMED_mappings.num_SNOMED_concept_codes)
PRINT CAST(@conflicting_ICD10CM_to_SNOMED_mappings AS VARCHAR) +
    ' ICD10CM codes have conflicting mappings to SNOMED in concept_relationship'

DECLARE @ICD10CM_to_SNOMED_mappings INT =
    (SELECT COUNT(DISTINCT(concept_ICD10.concept_id))
     FROM omop.cdm.concept_relationship concept_relationship,
          omop.cdm.concept concept_ICD10,
          omop.cdm.concept concept_SNOMED
     WHERE concept_ICD10.vocabulary_id = 'ICD10CM'
         AND concept_SNOMED.vocabulary_id = 'SNOMED'
         AND concept_relationship.relationship_id = 'Maps to'
         AND concept_ICD10.concept_id = concept_relationship.concept_id_1
         AND concept_SNOMED.concept_id = concept_relationship.concept_id_2)
PRINT CAST(@ICD10CM_to_SNOMED_mappings AS VARCHAR) + ' ICD10CM codes map to SNOMED in concept_relationship'

SELECT concept_ICD10.vocabulary_id, concept_ICD10.concept_code, concept_ICD10.concept_name, concept_ICD10.concept_id AS I10_concept_id,
       concept_relationship.relationship_id,
       concept_SNOMED.vocabulary_id, concept_SNOMED.concept_code, concept_SNOMED.concept_name 
FROM omop.cdm.concept_relationship concept_relationship,
     omop.cdm.concept concept_ICD10,
     omop.cdm.concept concept_SNOMED,
     @cardinality_I10_2_SNOMED_mappings cardinality_I10_2_SNOMED_mappings
WHERE concept_ICD10.vocabulary_id = 'ICD10CM'
    AND concept_SNOMED.vocabulary_id = 'SNOMED'
    AND concept_relationship.relationship_id = 'Maps to'
    AND concept_ICD10.concept_id = concept_relationship.concept_id_1
    AND concept_SNOMED.concept_id = concept_relationship.concept_id_2
    AND cardinality_I10_2_SNOMED_mappings.ICD10_concept_code = concept_ICD10.concept_code
    AND 1 < cardinality_I10_2_SNOMED_mappings.num_SNOMED_concept_codes
ORDER BY concept_ICD10.concept_code;
