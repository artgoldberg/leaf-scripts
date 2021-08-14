-- Create table rpt.Leaf_usagi.mapping_import with the same schema as src.usagi.mapping_import
-- rpt.Leaf_usagi.mapping_import will be used to map and set concepts in MSDW2

USE rpt;

IF (SCHEMA_ID('Leaf_usagi') IS NULL) 
BEGIN
    EXEC ('CREATE SCHEMA [Leaf_usagi] AUTHORIZATION [dbo]')
END
GO

-- DROP TABLE if it exists
DROP TABLE IF EXISTS Leaf_usagi.mapping_import;

SELECT TOP 1 *
INTO Leaf_usagi.mapping_import
FROM src.usagi.mapping_import

DELETE
FROM Leaf_usagi.mapping_import

-- Add primary key that prevents duplicate source-target mappings in Leaf_usagi.mapping_import
ALTER TABLE Leaf_usagi.mapping_import
ALTER COLUMN source_concept_id int NOT NULL;

ALTER TABLE Leaf_usagi.mapping_import
ALTER COLUMN source_concept_vocabulary_id NVARCHAR(20) NOT NULL;

ALTER TABLE Leaf_usagi.mapping_import
ALTER COLUMN target_concept_id int NOT NULL;

ALTER TABLE Leaf_usagi.mapping_import
ALTER COLUMN target_concept_vocabulary_id NVARCHAR(20) NOT NULL;

ALTER TABLE Leaf_usagi.mapping_import
ALTER COLUMN mapping_creation_user NVARCHAR(200) NOT NULL;

ALTER TABLE Leaf_usagi.mapping_import
ADD CONSTRAINT PK_mapping PRIMARY KEY (source_concept_id,
                                       source_concept_vocabulary_id,
                                       target_concept_id,
                                       target_concept_vocabulary_id,
                                       mapping_creation_user)

-- Insert Sharon's existing manual mappings from 'Epic diagnosis ID' to SNOMED in concept_relationship
INSERT INTO Leaf_usagi.mapping_import(source_concept_id,
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
