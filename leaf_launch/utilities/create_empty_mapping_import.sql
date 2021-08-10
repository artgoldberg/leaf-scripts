-- Create table rpt.usagi.mapping_import with the same schema as src.usagi.mapping_import
-- rpt.usagi.mapping_import will be used to map and set concepts in MSDW2

USE rpt;

CREATE SCHEMA usagi;
GO

SELECT TOP 1 *
INTO rpt.usagi.mapping_import
FROM src.usagi.mapping_import

DELETE
FROM rpt.usagi.mapping_import