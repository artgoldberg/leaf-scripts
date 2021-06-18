USE LeafDB
GO

DECLARE @rootId NVARCHAR(100) = '' /* <-- Make a root 'Medications' Root Concept and get it's app.Concept.Id */
DECLARE @leafMedSqlSetId INT  = -1 /* <-- Make a Leaf SQLSetID for the Clarity table/view you want to query 
                                          and get it's app.ConceptSqlSet.Id. The *usual* Clarity table for this
                                          is ***ORDER_MED*** */

DECLARE @clarityMedicationTable NVARCHAR(100) = 'EpicClarity.dbo.CLARITY_MEDICATION' /* The fully qualified name of the CLARITY_MEDICATION table.
                                                                                        Change the database name & schema accordingly */

; WITH x AS
(
       SELECT 
              M.MEDICATION_ID
            , THERA_CLASS_C_NAME
            , THERA_CLASS_C
            , PHARM_CLASS_C_NAME
            , PHARM_CLASS_C
            , PHARM_SUBCLASS_C_NAME
            , PHARM_SUBCLASS_C
            , NAME
            , SIMPLE_GENERIC_C_NAME
            , SIMPLE_GENERIC_C
            , STRENGTH
            , FORM
            , ROUTE
            , GENERIC_NAME
            , C = COUNT(*)
       FROM [Clarity].[dbo].[CLARITY_MEDICATION] M
                INNER JOIN Clarity.dbo.ORDER_MED O 
                     ON M.MEDICATION_ID = O.MEDICATION_ID
       WHERE M.THERA_CLASS_C_NAME IS NOT NULL
       GROUP BY
              M.MEDICATION_ID
            , THERA_CLASS_C_NAME
            , THERA_CLASS_C
            , PHARM_CLASS_C_NAME
            , PHARM_CLASS_C
            , PHARM_SUBCLASS_C_NAME
            , PHARM_SUBCLASS_C
            , NAME
            , SIMPLE_GENERIC_C_NAME
            , SIMPLE_GENERIC_C
            , STRENGTH
            , FORM
            , ROUTE
            , GENERIC_NAME
)   

INSERT INTO app.Concept 
(
      RootId
    , ParentId
    , ExternalId
    , ExternalParentId
    , IsPatientCountAutoCalculated
    , IsNumeric
    , IsParent
    , IsRoot
    , IsSpecializable
    , SqlSetId
    , SqlSetWhere
    , UiDisplayName
    , UiDisplayText
    , UiDisplayTooltip
    , AddDateTime
    , ContentLastUpdateDateTime
)


-- LEVEL 1: THERA_CLASS_C
SELECT DISTINCT
    RootId = @rootId
  , ParentId = @rootId
  , ExternalId = 'epic_thera_class_c:' + CONVERT(NVARCHAR(50),THERA_CLASS_C)
  , ExternalParentId = NULL
  , IsPatientCountAutoCalculated = 1
  , IsNumeric = 0
  , IsParent = 1
  , IsRoot = 0
  , IsSpecializable = 0
  , SqlSetId = @leafMedSqlSetId
  , SqlSetWhere = 'EXISTS (SELECT 1 FROM ' + @clarityMedicationTable + ' AS @CM WHERE @CM.THERA_CLASS_C_NAME = ''' + x.THERA_CLASS_C_NAME + ''' AND @.MEDICATION_ID = @CM.MEDICATION_ID)'
  , UiDisplayName = x.THERA_CLASS_C_NAME
  , UiDisplayText = 'Had medication order for ' + x.THERA_CLASS_C_NAME
  , UiDisplayTooltip = NULL
  , AddDateTime = GETDATE()
  , ContentLastUpdateDateTime = GETDATE()
FROM x

-- LEVEL 2: PHARM_CLASS_C
SELECT DISTINCT
    RootId = @rootId
  , ParentId = NULL
  , ExternalId = 'epic_pharm_class_c:' + CONVERT(NVARCHAR(50),PHARM_CLASS_C)
  , ExternalParentId = 'epic_thera_class_c:' + CONVERT(NVARCHAR(50),THERA_CLASS_C)
  , IsPatientCountAutoCalculated = 1
  , IsNumeric = 0
  , IsParent = 1
  , IsRoot = 0
  , IsSpecializable = 0
  , SqlSetId = @leafMedSqlSetId
  , SqlSetWhere = 'EXISTS (SELECT 1 FROM ' + @clarityMedicationTable + ' AS @CM WHERE @CM.PHARM_CLASS_C_NAME = ''' + x.PHARM_CLASS_C_NAME + ''' AND @.MEDICATION_ID = @CM.MEDICATION_ID)'
  , UiDisplayName = x.PHARM_CLASS_C_NAME
  , UiDisplayText = 'Had medication order for ' + x.PHARM_CLASS_C_NAME
  , UiDisplayTooltip = NULL
  , AddDateTime = GETDATE()
  , ContentLastUpdateDateTime = GETDATE()
FROM x
WHERE PHARM_CLASS_C IS NOT NULL

-- LEVEL 3: PHARM_SUBCLASS_C
SELECT DISTINCT
    RootId = @rootId
  , ParentId = NULL
  , ExternalId = 'epic_pharm_subclass_c:' + CONVERT(NVARCHAR(50),PHARM_SUBCLASS_C)
  , ExternalParentId = 'epic_pharm_class_c:' + CONVERT(NVARCHAR(50),PHARM_CLASS_C)
  , IsPatientCountAutoCalculated = 1
  , IsNumeric = 0
  , IsParent = 1
  , IsRoot = 0
  , IsSpecializable = 0
  , SqlSetId = @leafMedSqlSetId
  , SqlSetWhere = 'EXISTS (SELECT 1 FROM ' + @clarityMedicationTable + ' AS @CM WHERE @CM.PHARM_SUBCLASS_C_NAME = ''' + x.PHARM_SUBCLASS_C_NAME + ''' AND @.MEDICATION_ID = @CM.MEDICATION_ID)'
  , UiDisplayName = x.PHARM_SUBCLASS_C_NAME
  , UiDisplayText = 'Had medication order for ' + x.PHARM_SUBCLASS_C_NAME
  , UiDisplayTooltip = NULL
  , AddDateTime = GETDATE()
  , ContentLastUpdateDateTime = GETDATE()
FROM x
WHERE PHARM_SUBCLASS_C IS NOT NULL

-- LEVEL 4: SIMPLE_GENERIC_C_NAME
SELECT DISTINCT
    RootId = @rootId
  , ParentId = NULL
  , ExternalId = 'epic_simple_generic_c:' + CONVERT(NVARCHAR(50),SIMPLE_GENERIC_C)
  , ExternalParentId = 'epic_pharm_subclass_c:' + CONVERT(NVARCHAR(50),PHARM_SUBCLASS_C)
  , IsPatientCountAutoCalculated = 1
  , IsNumeric = 0
  , IsParent = 1
  , IsRoot = 0
  , IsSpecializable = 0
  , SqlSetId = @leafMedSqlSetId
  , SqlSetWhere = 'EXISTS (SELECT 1 FROM ' + @clarityMedicationTable + ' AS @CM WHERE @CM.SIMPLE_GENERIC_C_NAME = ''' + x.SIMPLE_GENERIC_C_NAME + ''' AND @.MEDICATION_ID = @CM.MEDICATION_ID)'
  , UiDisplayName = x.SIMPLE_GENERIC_C_NAME
  , UiDisplayText = 'Had medication order for ' + x.SIMPLE_GENERIC_C_NAME
  , UiDisplayTooltip = NULL
  , AddDateTime = GETDATE()
  , ContentLastUpdateDateTime = GETDATE()
FROM x
WHERE SIMPLE_GENERIC_C IS NOT NULL

-- LEVEL 5: STRENGTH
SELECT DISTINCT
    RootId = @rootId
  , ParentId = NULL
  , ExternalId = 'epic_simple_generic_c_strength:' + CONVERT(NVARCHAR(50),SIMPLE_GENERIC_C) + '_' + CONVERT(NVARCHAR(50),STRENGTH)
  , ExternalParentId = 'epic_simple_generic_c:' + CONVERT(NVARCHAR(50),SIMPLE_GENERIC_C)
  , IsPatientCountAutoCalculated = 1
  , IsNumeric = 0
  , IsParent = 1
  , IsRoot = 0
  , IsSpecializable = 0
  , SqlSetId = @leafMedSqlSetId
  , SqlSetWhere = 'EXISTS (SELECT 1 FROM ' + @clarityMedicationTable + ' AS @CM WHERE @CM.SIMPLE_GENERIC_C_NAME = ''' + x.SIMPLE_GENERIC_C_NAME + ''' AND @CM.STRENGTH = ''' + x.STRENGTH + ''' AND @.MEDICATION_ID = @CM.MEDICATION_ID)'
  , UiDisplayName = x.STRENGTH
  , UiDisplayText = 'Had medication order for ' + x.SIMPLE_GENERIC_C_NAME + ' ' + x.STRENGTH
  , UiDisplayTooltip = NULL
  , AddDateTime = GETDATE()
  , ContentLastUpdateDateTime = GETDATE()
FROM x
WHERE STRENGTH IS NOT NULL

-- SET ParentIds
UPDATE app.Concept
SET ParentId = p.Id
FROM app.Concept c
       INNER JOIN (SELECT p.Id, p.ParentId, p.ExternalId
                           FROM app.Concept p) p 
              ON c.ExternalParentID = p.ExternalID
WHERE c.SqlSetId = @leafMedSqlSetId
         AND c.ParentId IS NULL

-- SET IsParent flag
; WITH x AS 
(
    SELECT DISTINCT ParentConceptId = ParentId
    FROM app.Concept
    WHERE ParentId IS NOT NULL
)

UPDATE app.Concept
SET IsParent = CASE WHEN EXISTS (
                                    SELECT ParentConceptId
                                    FROM x child
                                    WHERE child.ParentConceptId = parent.Id
                                )
                    THEN 1 ELSE 0 END
FROM app.Concept parent
WHERE parent.SqlSetId = @leafMedSqlSetId
      AND parent.ExternalId LIKE 'epic_simple%'
