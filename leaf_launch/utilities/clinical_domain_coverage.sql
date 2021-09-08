/*
 * Evaluate the coverage of concepts (query facets) in Leaf, how well they cover the data in MSDW2
 * Author: Arthur.Goldberg@mssm.edu
 */
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
 * number of distinct concepts used in the cdm.condition_occurrence table.
 * This changes over time as both the concept table and the use of concepts in the clinical domain changes.
 *
 * The last coverage measurement is
 * 3) Used concepts, weighted by usage: the numerator is the number of occurrences in
 * a clinical domain in MSDW2 that are selected by a leaf node in the domain's hierarchy in the Leaf DB. 
 * And the denominator is the total number of occurrences in the clinical domain in MSDW2.
 */

CREATE PROCEDURE [app].[sp_calculate_domains_coverage]
	@schema NVARCHAR(100),              -- Schema containing the domain
	@domain NVARCHAR(100),              -- Domain's text name
	@domain_table NVARCHAR(100),        -- The CDM table that contains the domain's data
	@domain_column NVARCHAR(100),       -- The column in @domain_table that contains concept ids for the domain
	@concept_set_id INT                 -- The Id of the ConceptSqlSet for the domain in the Leaf DB
AS
BEGIN

END