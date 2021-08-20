/**
 * Leaf OMOP 5.3 bootstrap script.
 * Vitals
 */

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

BEGIN

    DECLARE @yes BIT = 1
    DECLARE @no  BIT = 0

    DECLARE @sqlset_person               INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom = 'omop.cdm_std.person')
    DECLARE @sqlset_visit_occurrence     INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom = 'omop.cdm_std.visit_occurrence')
    DECLARE @sqlset_condition_occurrence INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom = 'omop.cdm_std.condition_occurrence')
    DECLARE @sqlset_death                INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom = 'omop.cdm_std.death')
    DECLARE @sqlset_device_exposure      INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom = 'omop.cdm_std.device_exposure')
    DECLARE @sqlset_drug_exposure        INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom = 'omop.cdm_std.drug_exposure')
    DECLARE @sqlset_measurement          INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom = 'omop.cdm_std.measurement')
    DECLARE @sqlset_observation          INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom = 'omop.cdm_std.observation')
    DECLARE @sqlset_procedure_occurrence INT = (SELECT TOP 1 Id
                                                FROM LeafDB.app.ConceptSqlSet
                                                WHERE SqlSetFrom = 'omop.cdm_std.procedure_occurrence')

    DECLARE @vitals_root   NVARCHAR(50) = 'vitals'

	DECLARE @tempC         INT = 3020891
	DECLARE @heartRate     INT = 3027018
	DECLARE @respRate      INT = 3024171
	DECLARE @bpDiast       INT = 3012888
	DECLARE @bpSyst        INT = 3004249
	DECLARE @weight        INT = 3025315
	DECLARE @height        INT = 3036277
	DECLARE @pulse         INT = 3027018
	DECLARE @bmi           INT = 40540383

    ; WITH vitals AS
    (
        SELECT C.concept_name, C.concept_id, cnt = COUNT(DISTINCT person_id), concept_id_string = CONVERT(NVARCHAR(50), C.concept_id)
        FROM omop.cdm_std.measurement AS X
			 LEFT JOIN omop.cdm_std.concept AS C
				ON X.measurement_concept_id = C.concept_id
        WHERE X.measurement_concept_id IN (@bpSyst, @bpDiast, @bmi, @height, @weight, @heartRate, @tempC, @pulse, @respRate)
        GROUP BY C.concept_name, C.concept_id
    )

    /* INSERT */
    INSERT INTO LeafDB.app.Concept (ExternalId, ExternalParentId, [IsNumeric], IsParent, IsRoot, SqlSetId, SqlSetWhere,
                                       SqlFieldNumeric, UiDisplayName, UiDisplayText, UiDisplayUnits, UiNumericDefaultText, UiDisplayPatientCount)

    /* Root */
    SELECT ExternalId            = @vitals_root
         , ExternalParentId      = NULL
         , [IsNumeric]           = @no
         , IsParent              = @yes
         , IsRoot                = @yes
         , SqlSetId              = @sqlset_measurement
         , SqlSetWhere           = NULL
         , SqlFieldNumeric       = NULL
         , UiDisplayName         = 'Vitals'
         , UiDisplayText         = 'Had vitals measured'
         , UiDisplayUnits        = NULL
         , UiNumericDefaultText  = NULL
         , UiDisplayPatientCount = (SELECT COUNT(DISTINCT person_id) FROM omop.cdm_std.measurement WHERE measurement_concept_id IN (@bpSyst, @bpDiast, @bmi, @height, @weight, @heartRate, @tempC, @pulse, @respRate))

    UNION ALL

    /* Vitals */
    SELECT ExternalId            = 'vitals:' + X.concept_id_string
         , ExternalParentId      = @vitals_root
         , [IsNumeric]           = @yes
         , IsParent              = @no
         , IsRoot                = @no
         , SqlSetId              = @sqlset_measurement
         , SqlSetWhere           = '@.measurement_concept_id = ' + X.concept_id_string
         , SqlFieldNumeric       = '@.value_as_number'
         , UiDisplayName         = X.concept_name
         , UiDisplayText         = 'Had ' + X.concept_name + ' measured'
         , UiDisplayUnits        = NULL
         , UiNumericDefaultText  = 'of any result'
         , UiDisplayPatientCount = X.cnt
    FROM vitals AS X

    /**
    * Set ParentId based on ExternalIds
    */
    UPDATE LeafDB.app.Concept
    SET ParentId = P.Id
    FROM LeafDB.app.Concept AS C
        INNER JOIN (SELECT P.Id, P.ParentId, P.ExternalId
                    FROM LeafDB.app.Concept AS P) AS P
                        ON C.ExternalParentID = P.ExternalID
    WHERE C.ParentId IS NULL

    /**
    * Set RootIds
    */
    ; WITH roots AS
    (
        SELECT
		      RootId            = C.Id
            , RootUiDisplayName = C.UiDisplayName
            , C.IsRoot
            , C.Id
            , C.ParentId
            , C.UiDisplayName
        FROM LeafDB.app.Concept AS C
        WHERE C.IsRoot = 1

        UNION ALL

        SELECT roots.RootId
            , roots.RootUiDisplayName
            , C2.IsRoot
            , C2.Id
            , C2.ParentId
            , C2.UiDisplayName
        FROM roots
            INNER JOIN LeafDB.app.Concept AS C2
                ON C2.ParentId = roots.Id
    )

    UPDATE LeafDB.app.Concept
    SET RootId = roots.RootId
    FROM LeafDB.app.Concept AS C
        INNER JOIN roots
            ON C.Id = roots.Id
    WHERE C.RootId IS NULL

END