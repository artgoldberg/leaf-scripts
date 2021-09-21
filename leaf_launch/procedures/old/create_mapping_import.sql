/*
 * Create table rpt.Leaf_usagi.mapping_import with the same schema as src.usagi.mapping_import
 * Use it to hold existing, manual mappings from Epic to OMOP standard concepts
 * Create table Leaf_staging with same schema as src.usagi.mapping_import, which will eventually hold
 * mappings from Epic to OMOP standard concepts, created by Leaf scripts for loading into MSDW2
 * Author: Arthur.Goldberg@mssm.edu
 */

-- todo: Create modified version of conditions/create_mapping_import.sql