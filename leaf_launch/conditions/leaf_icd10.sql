/*
 * Generate a concept query hierarchy for Leaf that uses ICD-10-CM concepts and terminology.
 * Creates the LeafDB.app.Concept entries needed.
 * Uses concept table from Athena and custom concept_relationship entries.
 * Assumes that LeafDB.app.ConceptSqlSet contains a 'condition_occurrence' record and that
 * UMLS_ICD10 contains the hierarchical ICD10 relationships provided by the UMLS MRHIER.RRF table.
 *
 * Author: Arthur.Goldberg@mssm.edu
 * Author: Nic Dobbins
 */

-- Get the diagnosis table's Leaf Concept SqlSet from app.ConceptSqlSet.Id
DECLARE @SqlSetId INT
SET @SqlSetId = (SELECT Id
                 FROM LeafDB.app.ConceptSqlSet
                 WHERE SqlSetFrom LIKE '%condition_occurrence')

-- As discussed in https://github.com/uwrit/leaf/discussions/438, user queries employ ICD-10-CM.
-- But condition_occurrence.condition_concept_id will store an omop standard SNOMED value.
-- To enable queries on condition, we use mappings in concept_relationship between SNOMED and ICD-10-CM.
-- This defines a string that stores the portion of the SqlSetWhere code that is the same for all concepts:
DECLARE @ConstantSqlSetWhere NVARCHAR(1000)
SET @ConstantSqlSetWhere = 'EXISTS
                            (SELECT 1
                             FROM
                             omop.cdm_std.concept AS @C_SNOMED
                             INNER JOIN omop.cdm_std.concept_relationship AS @CR
                                 ON @C_SNOMED.concept_id = @CR.concept_id_2
                             INNER JOIN omop.cdm_std.concept AS @C_ICD10
                                 ON @C_ICD10.concept_id = @CR.concept_id_1
                             WHERE
                                 @C_SNOMED.vocabulary_id = ''SNOMED''
                                 AND @CR.relationship_id = ''Maps to''
                                 AND @C_ICD10.vocabulary_id = ''ICD10CM''
                                 AND @.condition_concept_id = @C_SNOMED.concept_id
                                 AND @C_ICD10.concept_code '


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
		[ExternalId]				   = 'UMLS_AUI:' + UMLS_ICD10.AUI
       ,[ExternalParentId]			   = 'UMLS_AUI:' + UMLS_ICD10.ParentAUI
       ,[IsPatientCountAutoCalculated] = 1
       ,[IsNumeric]					   = 0		
       ,[IsParent]					   = CASE WHEN EXISTS (SELECT 1
                                                           FROM rpt.leaf_scratch.UMLS_ICD10 AS O
                                                           WHERE UMLS_ICD10.AUI = O.ParentAUI)
                                                           THEN 1 ELSE 0 END
       ,[IsRoot]					   = CASE WHEN UMLS_ICD10.ParentAUI IS NULL THEN 1 ELSE 0 END
       ,[IsSpecializable]			   = 0
       ,[SqlSetId]					   = @SqlSetId
       ,[SqlSetWhere]				   = CONCAT( @ConstantSqlSetWhere, UMLS_ICD10.SqlSetWhere, ')' )
       ,[UiDisplayName]				   = UMLS_ICD10.uiDisplayName
       ,[UiDisplayText]				   = 'Had diagnosis of ' + UMLS_ICD10.uiDisplayName
       ,[AddDateTime]				   = GETDATE()
       ,[ContentLastUpdateDateTime]    = GETDATE()
	FROM rpt.leaf_scratch.UMLS_ICD10 AS UMLS_ICD10
	WHERE NOT EXISTS (SELECT 1
					  FROM LeafDB.app.Concept AS C
					  WHERE 'UMLS_AUI:' + UMLS_ICD10.AUI = C.ExternalId)

	-- Update Parent relationships in app.Concept where necessary
	UPDATE LeafDB.app.Concept
	SET Child.ParentId = Parent.Id
	FROM LeafDB.app.Concept Child
        INNER JOIN LeafDB.app.Concept Parent
            ON Child.ExternalParentID = Parent.ExternalId
	WHERE NOT Child.ParentId = Parent.Id
