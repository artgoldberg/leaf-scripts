USE [omop]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* Count non-NULL attributes in clinical data */
SELECT SchemaName = 'cdm', Source = 'Condition', NumNonNullRows = COUNT(*)
FROM cdm.condition_occurrence
WHERE condition_source_concept_id IS NOT NULL

UNION

SELECT SchemaName = 'cdm', Source = 'Drug', NumNonNullRows = COUNT(*)
FROM cdm.drug_exposure
WHERE drug_source_concept_id IS NOT NULL

UNION

SELECT SchemaName = 'cdm', Source = 'Labs', NumNonNullRows = COUNT(*)
FROM cdm.measurement
WHERE measurement_source_concept_id IS NOT NULL

UNION

SELECT SchemaName = 'cdm', Source = 'Procedures', NumNonNullRows = COUNT(*)
FROM cdm.procedure_occurrence
WHERE procedure_source_concept_id IS NOT NULL

UNION

SELECT SchemaName = 'cdm_std', Source = 'Condition', NumNonNullRows = COUNT(*)
FROM cdm_std.condition_occurrence
WHERE condition_source_concept_id IS NOT NULL
      AND condition_source_concept_code IS NOT NULL

UNION

SELECT SchemaName = 'cdm_std', Source = 'Drug', NumNonNullRows = COUNT(*)
FROM cdm_std.drug_exposure
WHERE drug_source_concept_id IS NOT NULL
      AND drug_source_concept_code IS NOT NULL

UNION

SELECT SchemaName = 'cdm_std', Source = 'Labs', NumNonNullRows = COUNT(*)
FROM cdm_std.measurement
WHERE measurement_source_concept_id IS NOT NULL
      AND measurement_source_concept_code IS NOT NULL

UNION

SELECT SchemaName = 'cdm_std', Source = 'Procedures', NumNonNullRows = COUNT(*)
FROM cdm_std.procedure_occurrence
WHERE procedure_source_concept_id IS NOT NULL
      AND procedure_source_concept_code IS NOT NULL

