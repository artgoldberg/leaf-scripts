-- From Joe
SELECT
  i10.vocabulary_id, i10.concept_code, i10.concept_name, i10.concept_id AS i10_concept_id,
  cr.relationship_id,
  c2.vocabulary_id, c2.concept_code, c2.concept_name,
  cr.etl_record_update_datetime, cr.etl_record_version_start_datetime 
FROM omop.cdm.concept i10
JOIN omop.cdm.concept_relationship cr ON cr.concept_id_1 = i10.concept_id
JOIN omop.cdm.concept c2 ON c2.concept_id = cr.concept_id_2
WHERE i10.vocabulary_id = N'ICD10CM'
  AND i10.concept_code = N'O44.03'
  AND cr.relationship_id = N'Maps to'
;