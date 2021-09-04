/*
 * Generate a concept query hierarchy for Leaf that uses ICD-10-CM concepts and terminology.
 * Creates the LeafDB.app.Concept entries needed.
 * Uses concept table from Athena and custom concept_relationship entries.
 * Assumes that LeafDB.app.ConceptSqlSet contains a 'condition_occurrence' record and that
 * UMLS_ICD10 contains the hierarchical ICD10 relationships provided by the UMLS MRHIER.RRF table.
 *
 * Author: Nic Dobbins
 * Author: Arthur.Goldberg@mssm.edu
 */

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Get the diagnosis table's Leaf Concept SqlSet from app.ConceptSqlSet.Id
DECLARE @SqlSetId INT
SET @SqlSetId = (SELECT Id
                 FROM LeafDB.app.ConceptSqlSet
                 -- TODO: Change this to '%[condition_occurrence]%' when it is ready
                 WHERE SqlSetFrom LIKE '%rpt.test_omop_conditions.condition_occurrence_deid%')

-- As discussed in https://github.com/uwrit/leaf/discussions/438, user queries employ ICD-10-CM.
-- But condition_occurrence.condition_concept_id will store an omop standard SNOMED value.
-- To enable queries on condition, we use mappings in concept_relationship from ICD-10-CM to SNOMED.
-- This defines a string that stores the portion of the SqlSetWhere code that is the same for all concepts:
DECLARE @ConstantSqlSetWhere NVARCHAR(1000)
SET @ConstantSqlSetWhere = 'EXISTS
                            (SELECT 1
                             FROM
                                 omop.cdm_deid_std.concept AS @C_ICD10CM,
                                 omop.cdm_deid_std.concept_relationship AS @CR,
                                 omop.cdm_deid_std.concept AS @C_SNOMED
                             WHERE
                                 @C_ICD10CM.vocabulary_id = ''ICD10CM''
                                 AND @C_ICD10CM.concept_id = @CR.concept_id_1
                                 AND @CR.relationship_id = ''Maps to''
                                 AND @C_SNOMED.vocabulary_id = ''SNOMED''
                                 AND @C_SNOMED.concept_id = @CR.concept_id_2
                                 AND @.condition_concept_id = @C_SNOMED.concept_id
                                 AND @C_ICD10CM.concept_code '

-- Delete existing ICD10 condition records
DELETE
FROM LeafDB.app.Concept
WHERE ExternalId LIKE 'UMLS_AUI:%'

INSERT INTO LeafDB.app.Concept
    (
       [ExternalId]
      ,[ExternalParentId]
      ,[IsPatientCountAutoCalculated]
      ,[IsNumeric]
      ,[IsParent]
      ,[IsRoot]
      ,[IsSpecializable]
      ,[SqlSetId]
      ,[SqlSetWhere]
      ,[UiDisplayName]
      ,[UiDisplayText]
      ,[AddDateTime]
      ,[ContentLastUpdateDateTime]
    )
    SELECT
        [ExternalId]                   = 'UMLS_AUI:' + UMLS_ICD10.AUI
       ,[ExternalParentId]             = 'UMLS_AUI:' + UMLS_ICD10.ParentAUI
       ,[IsPatientCountAutoCalculated] = 1
       ,[IsNumeric]                    = 0
       ,[IsParent]                     = CASE WHEN EXISTS (SELECT TOP 1 'child'
                                                           FROM rpt.leaf_scratch.UMLS_ICD10 AS child
                                                           WHERE UMLS_ICD10.AUI = child.ParentAUI)
                                                           THEN 1 ELSE 0 END
       ,[IsRoot]                       = CASE WHEN UMLS_ICD10.ParentAUI IS NULL THEN 1 ELSE 0 END
       ,[IsSpecializable]              = 0
       ,[SqlSetId]                     = @SqlSetId
       ,[SqlSetWhere]                  = CONCAT( @ConstantSqlSetWhere, UMLS_ICD10.SqlSetWhere, ')',
                                                  ' /* ', SUBSTRING(UMLS_ICD10.uiDisplayName, 1, 100), ' */ ' )
       ,[UiDisplayName]                = UMLS_ICD10.uiDisplayName
       ,[UiDisplayText]                = 'Had diagnosis of ' + UMLS_ICD10.uiDisplayName
       ,[AddDateTime]                  = GETDATE()
       ,[ContentLastUpdateDateTime]    = GETDATE()
    FROM rpt.leaf_scratch.UMLS_ICD10 AS UMLS_ICD10
    -- Don't insert duplicate Leaf concepts
    WHERE NOT EXISTS (SELECT TOP 1 'duplicate'
                      FROM LeafDB.app.Concept AS concept
                      WHERE 'UMLS_AUI:' + UMLS_ICD10.AUI = concept.ExternalId)

    -- Set RootIds for ICD10 conditions
    DECLARE @conditions_root_id VARCHAR(50) = (SELECT Id
                                               FROM LeafDB.app.Concept
                                               WHERE IsRoot = 1
                                                     AND SqlSetId = @SqlSetId)
    UPDATE LeafDB.app.Concept
    SET RootId = @conditions_root_id
    WHERE RootId IS NULL
          AND SqlSetId = @SqlSetId

    -- Update child - parent relationships in app.Concept where necessary
    UPDATE child
    SET ParentId = parent.Id
    FROM LeafDB.app.Concept AS child,
         LeafDB.app.Concept AS parent
    WHERE child.ExternalParentID = parent.ExternalID
          AND child.ExternalParentID IS NOT NULL
          AND child.ParentId IS NULL
