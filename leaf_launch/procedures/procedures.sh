#!/bin/bash

# Create mappings from 'Epic procedure codes' to CPT
# Results are new entries in the Leaf_usagi.Leaf_staging table

# use command: ./procedures.sh

# exit when any command fails
set -e

# Preparation: an active Kerberos ticket for Arthur Goldberg (goldba06) must be available to run sqlcmd -E
# TODO: Use a Kerberos keytab file so kinit doesn't need to be run by hand before this script
if ! klist 2> /dev/null | grep -q 'Principal: goldba06@MSSMCAMPUS.MSSM.EDU'
then
   echo "Error: a Kerberos ticket for goldba06@MSSMCAMPUS.MSSM.EDU is needed."
   exit 1
fi

# Hosts for the MSDW2 SQL Server database
MSDW2_PROD=msdw2-mssql-prd.msnyuhealth.org
MSDW2_SERVER=$MSDW2_PROD

echo "$(date +%Y-%m-%d\ %T): starting 'procedures.sh'"

sqlcmd -E -S $MSDW2_SERVER -i init_file_loads.sql

CURATED_PROCEDURE_MAPPINGS_DIR='/Users/arthur_at_sinai/gitOnMyLaptopLocal/sc_repos/leaf-scripts/leaf_launch/procedures/sharons_manual_mappings/tab_delimited/'

for MAPPING_FILE in Usagi_Procedure_1_SN_MAPPED.txt Usagi_SurgicalProcedures_1_SN_MAPPED.txt Usagi_SurgicalProcedures_2_SN_MAPPED.txt; do

    echo "loading $MAPPING_FILE ..."

    sqlcmd -E -S $MSDW2_SERVER -i prep_file_load.sql
    BCP rpt.leaf_scratch.temp_curated_procedure_mappings in "$CURATED_PROCEDURE_MAPPINGS_DIR$MAPPING_FILE" -S $MSDW2_SERVER -T \
        -F 2 -m 10 -c -r0x0A -e errors.log
    sqlcmd -E -S $MSDW2_SERVER -i finish_file_load.sql

done

# todo: Discard rows with equivalence = 'UNMATCHED'
# todo: Cast or convert fields as needed

echo "$(date +%Y-%m-%d\ %T): finishing 'procedures.sh'"
