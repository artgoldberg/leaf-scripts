/*
 * Create "Coming soon ..." entries in LeafDB
 * Author: Arthur.Goldberg@mssm.edu
 */

USE LeafDB;

DECLARE @yes BIT = 1
DECLARE @no  BIT = 0

DECLARE @labs_root_name VARCHAR(100) = 'LOINC labs search coming soon'
DECLARE @drugs_root_name VARCHAR(100) = 'RxNorm drugs search coming soon'
DECLARE @procedures_root_name VARCHAR(100) = 'CPT4 procedures search coming soon'

-- Don't create duplicates
DELETE
FROM app.Concept
WHERE concept.UiDisplayName IN (@labs_root_name,
                                @drugs_root_name,
                                @procedures_root_name)

INSERT INTO app.Concept (IsPatientCountAutoCalculated,
                         IsNumeric,
                         IsParent,
                         IsRoot,
                         IsSpecializable,
                         SqlSetId,
                         UiDisplayName,
                         AddDateTime,
                         ContentLastUpdateDateTime)
SELECT *
FROM (VALUES (@no,
              @no,
              @no,
              @yes,
              @no,
              (SELECT TOP 1 Id
               FROM app.ConceptSqlSet
               WHERE SqlSetFrom = 'omop.cdm_deid.measurement'),
              @labs_root_name,
              GETDATE(),
              GETDATE()),
             (@no,
              @no,
              @no,
              @yes,
              @no,
              (SELECT TOP 1 Id
               FROM app.ConceptSqlSet
               WHERE SqlSetFrom = 'omop.cdm_deid.drug_exposure'),
              @drugs_root_name,
              GETDATE(),
              GETDATE()),
             (@no,
              @no,
              @no,
              @yes,
              @no,
              (SELECT TOP 1 Id
               FROM app.ConceptSqlSet
               WHERE SqlSetFrom = 'omop.cdm_deid.procedure_occurrence'),
              @procedures_root_name,
              GETDATE(),
              GETDATE())
     ) AS X(col1,col2,col3,col4,col5,col6,col7,col8,col9)

UPDATE app.Concept
SET RootId = concept.Id
FROM app.Concept AS concept
WHERE concept.UiDisplayName IN (@labs_root_name,
                                @drugs_root_name,
                                @procedures_root_name)
