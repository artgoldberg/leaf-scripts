USE [omop]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- make temp table for source data
IF OBJECT_ID(N'tempdb..#SourceData') IS NOT NULL
	DROP TABLE #SourceData
CREATE TABLE #SourceData(
    SchemaName NVARCHAR(50)
    , [Source] NVARCHAR(200)
    , EpicConceptId INT
    , EpicConceptCode NVARCHAR(50)
    , EpicConceptName NVARCHAR(255)
    , EpicConceptValue NVARCHAR(300)
    , NumUses INT);

/*
 * Enumerate non-NULL source ids, codes, names and values in important clinical domains
 */
/* Conditions */
INSERT INTO #SourceData
SELECT SchemaName = 'cdm'
    , [Source] = 'Condition'
    , EpicConceptId = condition_status_concept_id
    , EpicConceptCode = ''
    , EpicConceptName = ''
    , EpicConceptValue = condition_source_value
    , NumUses = COUNT(*)
FROM cdm.condition_occurrence
WHERE condition_status_concept_id IS NOT NULL
    AND condition_source_value IS NOT NULL
GROUP BY condition_status_concept_id, condition_source_value

INSERT INTO #SourceData
SELECT SchemaName = 'cdm_std'
    , [Source] = 'Condition'
    , EpicConceptId = condition_status_concept_id
    , EpicConceptCode = condition_source_concept_code
    , EpicConceptName = condition_source_concept_name
    , EpicConceptValue = condition_source_value
    , NumUses = COUNT(*)
FROM cdm_std.condition_occurrence
WHERE condition_status_concept_id IS NOT NULL
    AND condition_source_concept_code IS NOT NULL
    AND condition_source_concept_name IS NOT NULL
    AND condition_source_value IS NOT NULL
GROUP BY condition_status_concept_id
	, condition_source_concept_code
	, condition_source_concept_name
	, condition_source_value

/* Drugs */
INSERT INTO #SourceData
SELECT SchemaName = 'cdm'
    , [Source] = 'Drug'
    , EpicConceptId = drug_source_concept_id
    , EpicConceptCode = ''
    , EpicConceptName = ''
    , EpicConceptValue = drug_source_value
    , NumUses = COUNT(*)
FROM cdm.drug_exposure
WHERE drug_source_concept_id IS NOT NULL
    AND drug_source_value IS NOT NULL
GROUP BY drug_source_concept_id, drug_source_value

INSERT INTO #SourceData
SELECT SchemaName = 'cdm_std'
    , [Source] = 'Drug'
    , EpicConceptId = drug_source_concept_id
    , EpicConceptCode = drug_source_concept_code
    , EpicConceptName = drug_source_concept_name
    , EpicConceptValue = drug_source_value
    , NumUses = COUNT(*)
FROM cdm_std.drug_exposure
WHERE drug_source_concept_id IS NOT NULL
    AND drug_source_concept_code IS NOT NULL
    AND drug_source_concept_name IS NOT NULL
    AND drug_source_value IS NOT NULL
GROUP BY drug_source_concept_id
	, drug_source_concept_code
	, drug_source_concept_name
	, drug_source_value

/* Labs */
INSERT INTO #SourceData
SELECT SchemaName = 'cdm'
    , [Source] = 'Labs'
    , EpicConceptId = measurement_source_concept_id
    , EpicConceptCode = ''
    , EpicConceptName = ''
    , EpicConceptValue = measurement_source_value
    , NumUses = COUNT(*)
FROM cdm.measurement
WHERE measurement_source_concept_id IS NOT NULL
    AND measurement_source_value IS NOT NULL
GROUP BY measurement_source_concept_id, measurement_source_value

INSERT INTO #SourceData
SELECT SchemaName = 'cdm_std'
    , [Source] = 'Labs'
    , EpicConceptId = measurement_source_concept_id
    , EpicConceptCode = measurement_source_concept_code
    , EpicConceptName = measurement_source_concept_name
    , EpicConceptValue = measurement_source_value
    , NumUses = COUNT(*)
FROM cdm_std.measurement
WHERE measurement_source_concept_id IS NOT NULL
    AND measurement_source_concept_code IS NOT NULL
    AND measurement_source_concept_name IS NOT NULL
    AND measurement_source_value IS NOT NULL
GROUP BY measurement_source_concept_id
	, measurement_source_concept_code
	, measurement_source_concept_name
	, measurement_source_value

/* Procedures */
INSERT INTO #SourceData
SELECT SchemaName = 'cdm'
    , [Source] = 'Procedures'
    , EpicConceptId = procedure_source_concept_id
    , EpicConceptCode = ''
    , EpicConceptName = ''
    , EpicConceptValue = procedure_source_value
    , NumUses = COUNT(*)
FROM cdm.procedure_occurrence
WHERE procedure_source_concept_id IS NOT NULL
    AND procedure_source_value IS NOT NULL
GROUP BY procedure_source_concept_id, procedure_source_value

INSERT INTO #SourceData
SELECT SchemaName = 'cdm_std'
    , [Source] = 'Procedures'
    , EpicConceptId = procedure_source_concept_id
    , EpicConceptCode = procedure_source_concept_code
    , EpicConceptName = procedure_source_concept_name
    , EpicConceptValue = procedure_source_value
    , NumUses = COUNT(*)
FROM cdm_std.procedure_occurrence
WHERE procedure_source_concept_id IS NOT NULL
    AND procedure_source_concept_code IS NOT NULL
    AND procedure_source_concept_name IS NOT NULL
    AND procedure_source_value IS NOT NULL
GROUP BY procedure_source_concept_id
	, procedure_source_concept_code
	, procedure_source_concept_name
	, procedure_source_value

SELECT *
FROM #SourceData
WHERE 1000 <= NumUses
ORDER BY SchemaName
    , [Source]
    , EpicConceptValue
