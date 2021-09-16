/*
 * Create table rpt.Leaf_usagi.mapping_import with the same schema as src.usagi.mapping_import
 * Use it to hold existing, manual mappings from Epic to OMOP standard concepts
 * Create table Leaf_staging with same schema as src.usagi.mapping_import, which will eventually hold
 * mappings from Epic to OMOP standard concepts, created by Leaf scripts for loading into MSDW2
 * Author: Arthur.Goldberg@mssm.edu
 */

USE rpt;

IF (SCHEMA_ID('Leaf_usagi') IS NULL) 
BEGIN
    EXEC ('CREATE SCHEMA [Leaf_usagi] AUTHORIZATION [dbo]')
END
GO

-- DROP mapping_import if it exists
DROP TABLE IF EXISTS Leaf_usagi.mapping_import;

SELECT TOP 1 *
INTO Leaf_usagi.mapping_import
FROM src.usagi.mapping_import

DELETE
FROM Leaf_usagi.mapping_import

-- Until src.usagi.mapping_import has good data
-- insert Sharon's existing manual mappings from 'Epic diagnosis ID' to SNOMED in concept_relationship
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
from omop.cdm_phi_std.concept_relationship,
     omop.cdm_phi_std.concept concept_EPIC,
     omop.cdm_phi_std.concept concept_SNOMED
WHERE
    concept_EPIC.vocabulary_id = 'EPIC EDG .1'
    AND relationship_id = 'Maps to'
    AND concept_SNOMED.vocabulary_id = 'SNOMED'
    AND concept_EPIC.concept_id = concept_id_1
    AND concept_SNOMED.concept_id = concept_id_2


-- Create Leaf_staging
-- DROP Leaf_staging if it exists
DROP TABLE IF EXISTS Leaf_usagi.Leaf_staging;

SELECT TOP 1 *
INTO Leaf_usagi.Leaf_staging
FROM src.usagi.mapping_import

DELETE
FROM Leaf_usagi.Leaf_staging

-- Add two primary keys that prevents duplicate source-target mappings in Leaf_usagi.Leaf_staging
ALTER TABLE Leaf_usagi.Leaf_staging
ALTER COLUMN source_concept_id INT NOT NULL;

ALTER TABLE Leaf_usagi.Leaf_staging
ALTER COLUMN target_concept_id INT NOT NULL;

ALTER TABLE Leaf_usagi.Leaf_staging
ADD CONSTRAINT PK_no_dupe_id_mappings UNIQUE (source_concept_id,
                                              target_concept_id)

ALTER TABLE Leaf_usagi.Leaf_staging
ALTER COLUMN source_concept_code NVARCHAR(50) NOT NULL;

ALTER TABLE Leaf_usagi.Leaf_staging
ALTER COLUMN source_concept_vocabulary_id NVARCHAR(20) NOT NULL;

ALTER TABLE Leaf_usagi.Leaf_staging
ALTER COLUMN target_concept_code NVARCHAR(50) NOT NULL;

ALTER TABLE Leaf_usagi.Leaf_staging
ALTER COLUMN target_concept_vocabulary_id NVARCHAR(20) NOT NULL;

ALTER TABLE Leaf_usagi.Leaf_staging
ADD CONSTRAINT PK_no_dupe_code_mappings UNIQUE (source_concept_code,
                                                source_concept_vocabulary_id,
                                                target_concept_code,
                                                target_concept_vocabulary_id)
