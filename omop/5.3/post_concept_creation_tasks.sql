-- Code to run after concepts or the clinical database (MSDW2) are updated.
/*
   Script to update patient counts in the concept hierarchy.
   To be customized for Sinai.
   Initial template from https://leafdocs.rit.uw.edu/administration/concept_reference/
*/
EXEC LeafDB.app.sp_CalculatePatientCounts
    @PersonIdField = 'person_id'                   -- PersonId field for this Leaf instance
  , @TargetDataBaseName = 'omop.cdm_std'           -- Clinical database to query for this Leaf instance
  , @TotalAllowedRuntimeInMinutes = 480            -- Total minutes to allow to entire process to run
  , @PerRootConceptAllowedRuntimeInMinutes = 120   -- Total minutes to allow a given Root Concept and children to run,
  , @SpecificRootConcept = NULL                    -- Optional, specify a Root ConceptId to only 
                                                   -- recalculate counts for part of the tree

-- Script to index concepts so they can be searched
-- From https://leafdocs.rit.uw.edu/administration/concepts/
EXEC LeafDB.app.sp_UpdateSearchIndexTables