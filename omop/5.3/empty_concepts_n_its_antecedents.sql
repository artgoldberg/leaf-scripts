/*
 * Empty the Leaf Concept table and the indicies and dependency maps that depend on it
 * Author: Arthur.Goldberg@mssm.edu
 */

/* Empty indices */
DELETE FROM LeafDB.app.ConceptForwardIndex;
DELETE FROM LeafDB.app.ConceptInvertedIndex;
DELETE FROM LeafDB.app.ConceptTokenizedIndex;

/* Empty dependency maps */
DELETE FROM LeafDB.rela.QueryConceptDependency;

/* Empty Concepts */
DELETE FROM LeafDB.app.Concept;
