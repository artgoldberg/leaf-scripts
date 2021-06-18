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
		[ExternalId]				   = 'UMLS_AUI:' + O.AUI
       ,[ExternalParentId]			   = 'UMLS_AUI:' + O.ParentAUI
       ,[IsPatientCountAutoCalculated] = 1
       ,[IsNumeric]					   = 0		
       ,[IsParent]					   = CASE WHEN EXISTS (SELECT 1 FROM #Output O2 WHERE O.AUI = O2.ParentAUI) THEN 1 ELSE 0 END
       ,[IsRoot]					   = CASE WHEN ParentAUI IS NULL THEN 1 ELSE 0 END
       ,[IsSpecializable]			   = 0
       ,[SqlSetId]					   = @SqlSetId /* <-- Your diagnosis table/view's Leaf Concept SqlSet from app.ConceptSqlSet.Id */
       ,[SqlSetWhere]				   = '@.YourDiagnosisCodeColumn ' + O.SqlSetWhere
       ,[UiDisplayName]				   = O.uiDisplayName
       ,[UiDisplayText]				   = 'Had diagnosis of ' + O.uiDisplayName
       ,[AddDateTime]				   = GETDATE()
       ,[ContentLastUpdateDateTime]    = GETDATE()
	FROM dbo.UMLS_ICD10 AS O
	WHERE NOT EXISTS (SELECT 1
					  FROM app.Concept AS C
					  WHERE 'UMLS_AUI:' + O.AUI = C.ExternalID)

	-- Update Parent Linkage
	UPDATE app.Concept
	SET ParentId = p.Id
	FROM app.Concept c
		 INNER JOIN (SELECT p.Id, p.ParentId, p.ExternalId
					 FROM app.Concept p) p 
			ON c.ExternalParentID = p.ExternalID
	WHERE EXISTS (SELECT 1 FROM #Output o WHERE 'UMLS_AUI:' + o.AUI = c.ExternalId)