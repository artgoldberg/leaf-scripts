/*
 * Evaluate the coverage of concepts (query facets) in Leaf, how well they cover the data in MSDW2
 * Author: Arthur.Goldberg@mssm.edu
 */
-- TODO: Everywhere replace test_omop_conditions.condition_occurrence_deid with omop.cdm_deid_std.condition_occurrence when it's ready

USE [LeafDB]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
 * The coverage of a clinical domain is quantified as the fraction of concepts in MSDW2 that are covered by
 * concepts in Leaf. This can be defined in multiple ways, but the basic idea is that the coverage is
 * a ratio of the number of concepts in the domain available in Leaf divided by the number of
 * concepts in the domain in MSDW2.
 * We define several types of coverages below, as different types will be suitable for different
 * circumstances.
 * In the first two measurements below the numerator
 * in a coverage ratio is the number of concepts that do not query a range of concepts in the clinical domain
 * in Leaf. These are the leaf (lower case) nodes in the domain's hierarchy in the Leaf DB.
 *
 * 1) All concepts: the denominator is the number of concepts in the domain's query vocabulary in the
 * omop.cdm.concept table. Note that this changes over time as the concept table changes.
 *
 * 2) Used concepts: the denominator includes all concepts in the vocabulary which are used in MSDW2 by the
 * clinical domain. For example, if the domain is conditions, then the denominator will be the
 * number of distinct concepts used in the condition_occurrence table.
 * This changes over time as either the concept table or the use of concepts in the clinical domain changes.
 *
 * The last coverage measurement is
 * 3) Used concepts, weighted by usage: the numerator is the number of occurrences in
 * a clinical domain in MSDW2 that are selected by a leaf node in the domain's hierarchy in the Leaf DB. 
 * And the denominator is the total number of occurrences in the clinical domain in MSDW2.
 */

/*
-- TODO: Create general-purpose procedure

CREATE PROCEDURE [app].[sp_calculate_domains_coverage]
	@schema NVARCHAR(100),              -- Schema containing the domain
	@domain NVARCHAR(100),              -- Domain's text name
	@domain_table NVARCHAR(100),        -- The CDM table that contains the domain's data
	@domain_column NVARCHAR(100),       -- The column in @domain_table that contains concept ids for the domain
	@concept_set_id INT                 -- The Id of the ConceptSqlSet for the domain in the Leaf DB
AS
*/

-- Example coverage analysis: conditions in cdm_deid_std

----- 1) All concepts -----
-- TODO: remove "TOP 1 " from similar queries in other programs; these SHOULD fail if more than 1 is returned
DECLARE @false BIT = 0

PRINT 'Conditions:'
DECLARE @sqlset_condition_occurrence INT = (SELECT Id
                                            FROM app.ConceptSqlSet
                                            -- TODO: Change this to '%omop.cdm_deid_std.condition_occurrence%' when it omop ready
                                            WHERE SqlSetFrom LIKE '%rpt.test_omop_conditions.condition_occurrence_deid%')
DECLARE @num_Leaf_condition_concepts BIGINT = (SELECT COUNT(*)
                                               FROM app.Concept
                                               WHERE SqlSetId = @sqlset_condition_occurrence
                                                     AND IsParent = @false)
DECLARE @num_condition_concepts BIGINT = (SELECT COUNT(*)
                                          FROM omop.cdm_deid_std.concept
                                          WHERE vocabulary_id = 'ICD10CM')
PRINT '   1) All concepts: ' +
      FORMAT(CAST(@num_Leaf_condition_concepts AS float) / CAST(@num_condition_concepts AS float), '##.00%', 'en-US')

----- 2) Used concepts -----

-- Count the ICD10 concepts used in MSDW2
DECLARE @num_ICD10_condition_concepts_used BIGINT =
        (SELECT COUNT(DISTINCT(concept_ICD10.concept_id))
         FROM rpt.test_omop_conditions.condition_occurrence_deid condition_occurrence,
              omop.cdm_deid_std.concept_relationship concept_relationship,
              omop.cdm_deid_std.concept concept_ICD10,
              omop.cdm_deid_std.concept concept_SNOMED
         WHERE
             -- Get records in rpt.test_omop_conditions.condition_occurrence_deid that use a SNOMED concept
             condition_occurrence.condition_concept_id = concept_SNOMED.concept_id
             -- Map the SNOMED concept to ICD10CM
             AND concept_SNOMED.vocabulary_id = 'SNOMED'
             AND concept_ICD10.vocabulary_id = 'ICD10CM'
             AND concept_relationship.relationship_id = 'Mapped from'
             AND concept_SNOMED.concept_id = concept_relationship.concept_id_1
             AND concept_ICD10.concept_id = concept_relationship.concept_id_2)

PRINT '   2) Used concepts ' +
      FORMAT(CAST(@num_Leaf_condition_concepts AS float) / CAST(@num_ICD10_condition_concepts_used AS float),
                                                                '##.00%', 'en-US')

----- 3) Used concepts, weighted by usage -----

-- TODO: do this with app.Concept instead of UMLS_ICD10; given the sub-queries required by the BINARY person_ids
-- currently requires complex parsing of SqlSetWhere
DECLARE @num_searchable_ICD10_condition_occurrences BIGINT =
        (SELECT COUNT(DISTINCT(condition_occurrence_id))
         FROM rpt.test_omop_conditions.condition_occurrence_deid condition_occurrence,
              omop.cdm_deid_std.concept_relationship concept_relationship,
              omop.cdm_deid_std.concept concept_ICD10,
              omop.cdm_deid_std.concept concept_SNOMED,
              rpt.leaf_scratch.UMLS_ICD10 AS UMLS_ICD10
         WHERE condition_occurrence.condition_concept_id = concept_SNOMED.concept_id
               AND concept_SNOMED.vocabulary_id = 'SNOMED'
               AND concept_ICD10.vocabulary_id = 'ICD10CM'
               AND concept_relationship.relationship_id = 'Mapped from'
               AND concept_SNOMED.concept_id = concept_relationship.concept_id_1
               AND concept_ICD10.concept_id = concept_relationship.concept_id_2
               AND UMLS_ICD10.CodeCount = 1
               AND UMLS_ICD10.MinCode = concept_ICD10.concept_code)

DECLARE @num_condition_occurrences BIGINT =
        (SELECT COUNT(*)
         FROM rpt.test_omop_conditions.condition_occurrence_deid condition_occurrence)

PRINT '   3) Used concepts, weighted by usage ' +
      FORMAT(CAST(@num_searchable_ICD10_condition_occurrences AS float) / CAST(@num_condition_occurrences AS float),
                                                                               '##.00%', 'en-US')
