-- Schema for table mapping diagnosis concept ids

USE rpt;

IF (NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'LEAF_SCRATCH' 
                 AND  TABLE_NAME = 'conditions_map'))
BEGIN
    CREATE TABLE LEAF_SCRATCH.conditions_map
    (  
        EPIC_CONCEPT_CODE NVARCHAR(50) NOT NULL PRIMARY KEY,
        EPIC_CONCEPT_NAME NVARCHAR(200) NOT NULL,
        ICD10_CONCEPT_CODE NVARCHAR(50),
        ICD10_CONCEPT_NAME NVARCHAR(200),
        SNOMED_CONCEPT_CODE NVARCHAR(50),
        SNOMED_CONCEPT_NAME NVARCHAR(200),
        -- Relationship of Sharon's hand-coded Epic -> SNOMED mapping to automated mapping
        HAND_MAP_STATUS NVARCHAR(50),
        SOURCES NVARCHAR(50) NOT NULL,     -- Sources for a record
        COMMENT NVARCHAR(200)
    );
END

