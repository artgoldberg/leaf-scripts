/*
 * Create mappings from 'Epic drug exposure code' to RxNorm
 * Results are new entries in the Leaf_usagi.Leaf_staging table
 * Author: Arthur.Goldberg@mssm.edu
 */

/*
Must be executed as goldba06@MSSMCAMPUS.MSSM.EDU.

Steps
0. Create conditions_map table
1. 
2. 
3. Integrate Sharon's existing manual mappings of 'Epic drug exposure code' to RxNorm, from rpt.Leaf_usagi.mapping_import
3a. If manual mapping is consistent, mark conditions_map.hand_map_status 'CONSISTENT'
3b. If manual mapping conflicts, mark conditions_map.hand_map_status 'CONFLICTED',
    use the manual value selected for RxNorm, and update sources
3c. If manual mapping is missing, mark conditions_map.hand_map_status 'MISSING',
    add 'Epic diagnosis ID' and RxNorm values, and update sources
4. Validate the conditions_map
5. Insert new mappings into rpt.Leaf_usagi.Leaf_staging
*/


-- 3. Integrate Sharon's existing manual mappings of 'Epic drug exposure code' to RxNorm
-- AO 2021-08-25, this returns nothing
SELECT concept_Epic.concept_id AS 'Epic concept_id',
       concept_Epic.concept_code AS 'Epic concept_code',
       concept_Epic.concept_name AS 'Epic concept_name',
       concept_Epic.vocabulary_id AS 'Epic vocabulary',
       concept_RxNorm.concept_id AS 'RxNorm concept_id',
       concept_RxNorm.concept_code AS 'RxNorm concept_code',
       concept_RxNorm.concept_name AS 'RxNorm concept_name',
       concept_Epic.vocabulary_id AS 'RxNorm vocabulary',
       'Sharon Nirenberg',
       GETDATE()    -- todo: should be an earlier date; find and use it
from omop.cdm_phi_std.concept_relationship,
     omop.cdm_phi_std.concept concept_Epic,
     omop.cdm_phi_std.concept concept_RxNorm
WHERE concept_Epic.vocabulary_id = 'EPIC ERX .1'
      AND relationship_id = 'Maps to'
      AND concept_RxNorm.vocabulary_id IN ('RxNorm', 'RxNorm Extension')
      AND concept_Epic.concept_id = concept_id_1
      AND concept_RxNorm.concept_id = concept_id_2;

-- And AO 2021-08-25, this also returns nothing
SELECT *
FROM src.usagi.mapping_import
WHERE source_concept_vocabulary_id = 'EPIC ERX .1'
