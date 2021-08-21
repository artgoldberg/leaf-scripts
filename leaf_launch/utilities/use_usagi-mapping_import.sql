/*
 * Example query that could be used to extract curated concept mappings from src.usagi.mapping_import
 * Author: Timothy Quinn <Timothy.Quinn@mountsinai.org>
 */

SELECT COALESCE(mi.source_concept_id,            sc.concept_id   ) AS source_concept_id,
                mi.source_concept_code,
                mi.source_concept_name,
                mi.source_concept_vocabulary_id,
       COALESCE(mi.target_concept_id,            tc.concept_id   ) AS target_concept_id,
       COALESCE(mi.target_concept_code,          tc.concept_code ) AS target_concept_code,
       COALESCE(mi.target_concept_name,          tc.concept_name ) AS target_concept_name,
       COALESCE(mi.target_concept_vocabulary_id, tc.vocabulary_id) AS target_concept_vocabulary_id
FROM src.usagi.mapping_import mi
    JOIN omop.cdm.concept sc
         ON mi.source_concept_code = sc.concept_code
         AND mi.source_concept_vocabulary_id = sc.vocabulary_id
    LEFT JOIN omop.cdm.concept tc
         ON mi.target_concept_id = tc.concept_id
         OR (mi.target_concept_code = tc.concept_code
         AND mi.target_concept_vocabulary_id = tc.vocabulary_id)
WHERE mi.source_concept_vocabulary_id IN ('EPIC EDG .1', 'EPIC EAP .1', 'EPIC ERX .1', 'EPIC ORP .1', 'EPIC LRR .1');
