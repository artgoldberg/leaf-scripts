/*
 * Evaluate properties that should be satisfied by data used by the conditions concept queries
 * Author: Arthur.Goldberg@mssm.edu
 */

-- UMLS_ICD10 should not contain duplicate entries

-- Duplicate AUI values
SELECT duped_AUI
FROM (SELECT AUI duped_AUI,
             COUNT(*) num_records
      FROM rpt.leaf_scratch.UMLS_ICD10
      GROUP BY AUI) sub_query,
      rpt.leaf_scratch.UMLS_ICD10 UMLS_ICD10
WHERE 1 < num_records
ORDER BY duped_AUI;

-- Duplicate display names
SELECT duped_UI_display_name,
       AUI,
       MinCode,
       MaxCode,
       SqlSetWhere
FROM (SELECT UiDisplayName duped_UI_display_name,
             COUNT(AUI) num_records
      FROM rpt.leaf_scratch.UMLS_ICD10
      GROUP BY UiDisplayName) sub_query,
      rpt.leaf_scratch.UMLS_ICD10 UMLS_ICD10
WHERE 1 < num_records
      AND UMLS_ICD10.UiDisplayName = duped_UI_display_name
ORDER BY duped_UI_display_name;

-- Duplicate where clauses
SELECT duped_SqlSetWhere,
       AUI,
       MinCode,
       MaxCode,
       SqlSetWhere,
       UiDisplayName
FROM (SELECT SqlSetWhere duped_SqlSetWhere,
             COUNT(AUI) num_records
      FROM rpt.leaf_scratch.UMLS_ICD10
      GROUP BY SqlSetWhere) sub_query,
      rpt.leaf_scratch.UMLS_ICD10 UMLS_ICD10
WHERE 1 < num_records
      AND UMLS_ICD10.SqlSetWhere = duped_SqlSetWhere
ORDER BY duped_SqlSetWhere;


-- After running conditions.sql and leaf_icd10.sql, Concept should not contain duplicate entries

-- Duplicated display names
SELECT duped_UI_display_name,
       ExternalId,
       ExternalParentId,
       SqlSetWhere
FROM (SELECT UiDisplayName duped_UI_display_name,
             COUNT(Id) num_records
      FROM LeafDB.app.Concept
      GROUP BY UiDisplayName) sub_query,
      LeafDB.app.Concept Concept
WHERE 1 < num_records
      AND Concept.UiDisplayName = duped_UI_display_name
ORDER BY duped_UI_display_name;

-- Duplicate where clauses
SELECT duped_SqlSetWhere,
       ExternalId,
       ExternalParentId,
       UiDisplayName
FROM (SELECT SqlSetWhere duped_SqlSetWhere,
             COUNT(Id) num_records
      FROM LeafDB.app.Concept
      GROUP BY SqlSetWhere) sub_query,
      LeafDB.app.Concept Concept
WHERE 1 < num_records
      AND Concept.SqlSetWhere = duped_SqlSetWhere
ORDER BY duped_SqlSetWhere;
