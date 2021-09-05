-- Find pregnant male patients
DECLARE @IsIdentified BIT = 0;
DECLARE @IsResearch BIT = 1;
DECLARE @IsQI BIT = 0;
WITH wrapper (personId) AS (
    SELECT
        P0.person_id
    FROM
        (
            SELECT
                _S000.person_id
            FROM
                (
                    SELECT
                        [condition_occurrence_id],
                        [person_id] = CONVERT(NVARCHAR(64), [person_id], 2),
                        [condition_concept_id],
                        [condition_start_date],
                        [condition_start_datetime],
                        [condition_end_date],
                        [condition_end_datetime],
                        [condition_type_concept_id],
                        [stop_reason],
                        [provider_id],
                        [visit_occurrence_id],
                        [visit_detail_id],
                        [condition_source_value],
                        [condition_source_concept_id],
                        [condition_status_source_value],
                        [condition_status_concept_id]
                    FROM
                        rpt.test_omop_conditions.condition_occurrence_deid
                ) AS _S000
            WHERE
                EXISTS (
                    SELECT
                        1
                    FROM
                        omop.cdm_deid_std.concept AS _S000C_ICD10CM,
                        omop.cdm_deid_std.concept_relationship AS _S000CR,
                        omop.cdm_deid_std.concept AS _S000C_SNOMED
                    WHERE
                        _S000C_ICD10CM.vocabulary_id = 'ICD10CM'
                        AND _S000C_ICD10CM.concept_id = _S000CR.concept_id_1
                        AND _S000CR.relationship_id = 'Maps to'
                        AND _S000C_SNOMED.vocabulary_id = 'SNOMED'
                        AND _S000C_SNOMED.concept_id = _S000CR.concept_id_2
                        AND _S000.condition_concept_id = _S000C_SNOMED.concept_id
                        AND _S000C_ICD10CM.concept_code BETWEEN 'O00.00'
                        AND 'O9A.53'
                )
            GROUP BY
                _S000.person_id
        ) AS P0
    INTERSECT
    SELECT
        P1.person_id
    FROM
        (
            SELECT
                _S100.person_id
            FROM
                (
                    SELECT
                        [person_id] = CONVERT(NVARCHAR(64), [person_id], 2),
                        [gender_concept_id],
                        [year_of_birth],
                        [month_of_birth],
                        [day_of_birth],
                        [birth_datetime],
                        [race_concept_id],
                        [ethnicity_concept_id],
                        [location_id],
                        [provider_id],
                        [care_site_id],
                        [person_source_value],
                        [gender_source_value],
                        [gender_source_concept_id],
                        [race_source_value],
                        [race_source_concept_id],
                        [ethnicity_source_value],
                        [ethnicity_source_concept_id]
                    FROM
                        omop.cdm_deid_std.person
                ) AS _S100
            WHERE
                /* MALE */
                _S100.gender_concept_id = 8507
            UNION ALL
            SELECT
                _S101.person_id
            FROM
                (
                    SELECT
                        [person_id] = CONVERT(NVARCHAR(64), [person_id], 2),
                        [gender_concept_id],
                        [year_of_birth],
                        [month_of_birth],
                        [day_of_birth],
                        [birth_datetime],
                        [race_concept_id],
                        [ethnicity_concept_id],
                        [location_id],
                        [provider_id],
                        [care_site_id],
                        [person_source_value],
                        [gender_source_value],
                        [gender_source_concept_id],
                        [race_source_value],
                        [race_source_concept_id],
                        [ethnicity_source_value],
                        [ethnicity_source_concept_id]
                    FROM
                        omop.cdm_deid_std.person
                ) AS _S101
            WHERE
                /* Male */
                _S101.gender_concept_id = 2000001171
        ) AS P1
)
SELECT 'Num pregnant male patients', COUNT(personId)
FROM
    wrapper