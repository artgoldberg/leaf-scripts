/*
 * Create mappings from 'Epic procedure codes' to CPT
 * Results are new entries in the Leaf_usagi.Leaf_staging table
 * Author: Arthur.Goldberg@mssm.edu
 */

/*
Must be executed as goldba06@MSNYUHEALTH.ORG.

Steps
0. Create procedures_map table
1. Map 'Epic procedure codes' to CPT, from the Epic concept table src.caboodle.ProcedureDim 
2. Integrate Sharon's existing manual mappings of 'Epic procedure codes' to CPT, from rpt.Leaf_usagi.mapping_import
2a. If manual mapping is consistent, mark procedures_map.hand_map_status 'CONSISTENT'
2b. If manual mapping conflicts, mark procedures_map.hand_map_status 'CONFLICTED',
    use the manual value selected for CPT, and update sources
2c. If manual mapping is missing, mark procedures_map.hand_map_status 'MISSING',
    add 'Epic procedure codes' and CPT values, and update sources
3. Validate the procedures_map
4. Insert new mappings into rpt.Leaf_usagi.Leaf_staging
*/


