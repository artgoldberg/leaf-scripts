-- Are the icd10 to SNOMED maps already in concept_relationship?
/*
SELECT DISTINCT concept_ICD10.concept_id ICD10_concept_id,
       concept_ICD10.concept_code ICD10_concept_code,
       concept_ICD10.concept_name ICD10_concept_name,
       concept_SNOMED.concept_id SNOMED_concept_id,
       concept_SNOMED.concept_code SNOMED_concept_code,
       concept_SNOMED.concept_name SNOMED_concept_name
FROM rpt.leaf_scratch.conditions_map conditions_map,
     omop.cdm_std.concept concept_ICD10,
     omop.cdm_std.concept concept_SNOMED,
     omop.cdm_std.concept_relationship concept_relationship
WHERE concept_ICD10.vocabulary_id = 'ICD10CM'
      AND concept_ICD10.concept_code = conditions_map.ICD10_concept_code
      AND concept_SNOMED.vocabulary_id = 'SNOMED'
      AND concept_SNOMED.concept_code = conditions_map.SNOMED_concept_code
      AND concept_ICD10.concept_id = concept_relationship.concept_id_1
      AND concept_relationship.relationship_id = 'Maps to'
      AND concept_SNOMED.concept_id = concept_relationship.concept_id_2

SELECT DISTINCT concept_ICD10.concept_id ICD10_concept_id,
       concept_ICD10.concept_code ICD10_concept_code,
       concept_ICD10.concept_name ICD10_concept_name,
       concept_SNOMED.concept_id SNOMED_concept_id,
       concept_SNOMED.concept_code SNOMED_concept_code,
       concept_SNOMED.concept_name SNOMED_concept_name
FROM rpt.leaf_scratch.conditions_map conditions_map,
     omop.cdm_std.concept concept_ICD10,
     omop.cdm_std.concept concept_SNOMED
WHERE concept_ICD10.vocabulary_id = 'ICD10CM'
      AND concept_ICD10.concept_code = conditions_map.ICD10_concept_code
      AND concept_SNOMED.vocabulary_id = 'SNOMED'
      AND concept_SNOMED.concept_code = conditions_map.SNOMED_concept_code
*/

-- Are the ICD10 -> SNOMED r'ships the same as the inversion of the ICD10 -> SNOMED r'ships?
-- ICD10 -> SNOMED:
IF OBJECT_ID(N'tempdb..#tmp_ICD10_maps_to_SNOMED') IS NOT NULL
	DROP TABLE #tmp_ICD10_maps_to_SNOMED

SELECT DISTINCT concept_ICD10.concept_id ICD10_concept_id,
                concept_ICD10.concept_code ICD10_concept_code,
                concept_ICD10.concept_name ICD10_concept_name,
                concept_SNOMED.concept_id SNOMED_concept_id,
                concept_SNOMED.concept_code SNOMED_concept_code,
                concept_SNOMED.concept_name SNOMED_concept_name
INTO #tmp_ICD10_maps_to_SNOMED
FROM omop.cdm_std.concept concept_ICD10,
     omop.cdm_std.concept concept_SNOMED,
     omop.cdm_std.concept_relationship concept_relationship
WHERE concept_ICD10.vocabulary_id = 'ICD10CM'
      AND concept_ICD10.concept_id = concept_relationship.concept_id_1
      AND concept_relationship.relationship_id = 'Maps to'
      AND concept_SNOMED.vocabulary_id = 'SNOMED'
      AND concept_SNOMED.concept_id = concept_relationship.concept_id_2;

-- SNOMED -> ICD10 using 'Maps from', which should invert the ICD10 -> SNOMED map
IF OBJECT_ID(N'tempdb..#tmp_SNOMED_mapped_from_ICD10') IS NOT NULL
	DROP TABLE #tmp_SNOMED_mapped_from_ICD10

SELECT DISTINCT concept_ICD10.concept_id ICD10_concept_id,
                concept_ICD10.concept_code ICD10_concept_code,
                concept_ICD10.concept_name ICD10_concept_name,
                concept_SNOMED.concept_id SNOMED_concept_id,
                concept_SNOMED.concept_code SNOMED_concept_code,
                concept_SNOMED.concept_name SNOMED_concept_name
INTO #tmp_SNOMED_mapped_from_ICD10
FROM omop.cdm_std.concept concept_SNOMED,
     omop.cdm_std.concept concept_ICD10,
     omop.cdm_std.concept_relationship concept_relationship
WHERE concept_SNOMED.vocabulary_id = 'SNOMED'
      AND concept_SNOMED.concept_id = concept_relationship.concept_id_1
      AND concept_relationship.relationship_id = 'Mapped from'
      AND concept_ICD10.vocabulary_id = 'ICD10CM'
      AND concept_ICD10.concept_id = concept_relationship.concept_id_2;

-- Both of these counts should be 0
SELECT COUNT(*) FROM (SELECT *
                      FROM #tmp_SNOMED_mapped_from_ICD10
                      EXCEPT
                      SELECT *
                      FROM #tmp_ICD10_maps_to_SNOMED) tmp;

SELECT COUNT(*) FROM (SELECT *
                      FROM #tmp_ICD10_maps_to_SNOMED
                      EXCEPT
                      SELECT *
                      FROM #tmp_SNOMED_mapped_from_ICD10) tmp;

-- SNOMED -> ICD10 ... this result table is empty
SELECT DISTINCT concept_ICD10.concept_id ICD10_concept_id,
                concept_ICD10.concept_code ICD10_concept_code,
                concept_ICD10.concept_name ICD10_concept_name,
                concept_SNOMED.concept_id SNOMED_concept_id,
                concept_SNOMED.concept_code SNOMED_concept_code,
                concept_SNOMED.concept_name SNOMED_concept_name
FROM omop.cdm_std.concept concept_SNOMED,
     omop.cdm_std.concept concept_ICD10,
     omop.cdm_std.concept_relationship concept_relationship
WHERE concept_SNOMED.vocabulary_id = 'SNOMED'
      AND concept_SNOMED.concept_id = concept_relationship.concept_id_1
      AND concept_relationship.relationship_id = 'Maps to'
      AND concept_ICD10.vocabulary_id = 'ICD10CM'
      AND concept_ICD10.concept_id = concept_relationship.concept_id_2


