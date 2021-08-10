-- Create table rpt.Leaf_usagi.mapping_import with the same schema as src.usagi.mapping_import
-- rpt.Leaf_usagi.mapping_import will be used to map and set concepts in MSDW2

USE rpt;

CREATE SCHEMA Leaf_usagi;
GO

SELECT TOP 1 *
INTO rpt.Leaf_usagi.mapping_import
FROM src.usagi.mapping_import

DELETE
FROM rpt.Leaf_usagi.mapping_import

-- Insert Sharon's existing manual mappings in concept_relationship of 'Epic diagnosis ID' to SNOMED
INSERT INTO rpt.Leaf_usagi.mapping_import(source_concept_id,
                                     source_concept_code,
                                     source_concept_name,
                                     source_concept_vocabulary_id,
                                     target_concept_id,
                                     target_concept_code,
                                     target_concept_name,
                                     target_concept_vocabulary_id,
                                     mapping_creation_user,
                                     mapping_creation_datetime)
SELECT concept_EPIC.concept_id,
       concept_EPIC.concept_code,
       concept_EPIC.concept_name,
       'EPIC EDG .1',
       concept_SNOMED.concept_id,
       concept_SNOMED.concept_code,
       concept_SNOMED.concept_name,
       'SNOMED',
       'Sharon Nirenberg',
       GETDATE()    -- todo: should be an earlier date; find and use it
from omop.cdm_std.concept_relationship concept_relationship,
     omop.cdm_std.concept concept_EPIC,
     omop.cdm_std.concept concept_SNOMED
WHERE
    concept_EPIC.vocabulary_id = 'EPIC EDG .1'
    AND concept_relationship.relationship_id = 'Maps to'
    AND concept_SNOMED.vocabulary_id = 'SNOMED'
    AND concept_EPIC.concept_id = concept_relationship.concept_id_1
    AND concept_SNOMED.concept_id = concept_relationship.concept_id_2
