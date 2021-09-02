/*
  Code to run after Leaf concepts or the clinical database (MSDW2) are updated.
  1. Index concepts so they can be searched
  2. Update patient counts in the concept hierarchy
  Initial template from https://leafdocs.rit.uw.edu/administration/concept_reference/
*/

-- Script to index concepts so they can be searched
-- From https://leafdocs.rit.uw.edu/administration/concepts/
EXEC LeafDB.app.sp_UpdateSearchIndexTables;

EXEC LeafDB.app.sp_CalculatePatientCounts
    @PersonIdField = 'person_id'                   -- PersonId field for this Leaf instance
  , @TargetDataBaseName = 'omop.cdm_deid_std'      -- Clinical database to query for this Leaf instance
  , @TotalAllowedRuntimeInMinutes = 360            -- Total minutes to allow to entire process to run
  , @PerRootConceptAllowedRuntimeInMinutes = 1200  -- Total minutes to allow a given Root Concept and children to run,
  , @SpecificRootConcept = NULL                    -- Optional, specify a Root ConceptId to only 
                                                   -- recalculate counts for part of the tree
