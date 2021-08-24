-- Example of a query generated by Leaf at run-time
SELECT
    P0.person_id
FROM
    (
        SELECT
            _S000.person_id
        FROM
            rpt.test_omop_conditions.condition_occurrence AS _S000
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    omop.cdm_deid.concept AS _S000C_ICD10CM,
                    omop.cdm_deid.concept_relationship AS _S000CR,
                    omop.cdm_deid.concept AS _S000C_SNOMED
                WHERE
                    _S000C_ICD10CM.vocabulary_id = 'ICD10CM'
                    AND _S000C_ICD10CM.concept_id = _S000CR.concept_id_1
                    AND _S000CR.relationship_id = 'Maps to'
                    AND _S000C_SNOMED.vocabulary_id = 'SNOMED'
                    AND _S000C_SNOMED.concept_id = _S000CR.concept_id_2
                    AND _S000.condition_concept_id = _S000C_SNOMED.concept_id
                    AND _S000C_ICD10CM.concept_code BETWEEN 'Q35.1'
                    AND 'Q37.9'
            )
        GROUP BY
            _S000.person_id
    ) AS P0
