#!/bin/bash

# Update the LeafDB after the de-identified schema changes
# Needed whenever clinical records or concepts are added, deleted or updated

# use command ./update_leaf.sql

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

echo "$(date +%Y-%m-%d\ %T): starting 'update_leaf.sh'"

### Empty tables in the LeafDB to avoid duplicates ###
echo "$(date +%T): running 'empty_custom_Leaf_data_n_their_antecedents.sql'"
sqlcmd -E -S $MSDW2_SERVER -i empty_custom_Leaf_data_n_their_antecedents.sql

### Alter ConceptSqlSet to handle sub-queries in SqlSetFrom needed for BINARY person_ids  ###
echo "$(date +%T): running 'alter_ConceptSqlSet.sql'"
sqlcmd -E -S $MSDW2_SERVER -i alter_ConceptSqlSet.sql

### Run omop 5.3 scripts that initialize the configuration in ConceptSqlSet and create small sets of concepts ###
echo "$(date +%T): running '1_sqlsets.sql'"
sqlcmd -E -S $MSDW2_SERVER -i 1_sqlsets.sql
echo "$(date +%T): running '2_demographics.sql'"
sqlcmd -E -S $MSDW2_SERVER -i 2_demographics.sql
echo "$(date +%T): running '3_visits.sql'"
sqlcmd -E -S $MSDW2_SERVER -i 3_visits.sql
echo "$(date +%T): running '5_vitals.sql'"
sqlcmd -E -S $MSDW2_SERVER -i 5_vitals.sql
echo "$(date +%T): running '8_other.sql'"
sqlcmd -E -S $MSDW2_SERVER -i 8_other.sql

##### Load the concepts for clinical domains #####

### Load the conditions concepts ###
echo "$(date +%T): running 'leaf_icd10.sql'"
sqlcmd -E -S $MSDW2_SERVER -i ../../leaf_launch/conditions/leaf_icd10.sql

### Load the procedures concepts ###

### Load the laboratory concepts ###

### Load the drug exposure concepts ###

### Load "Coming soon" for concepts that do not yet have data ###
echo "$(date +%T): running 'coming_soon.sql'"
sqlcmd -E -S $MSDW2_SERVER -i ../../leaf_launch/utilities/coming_soon.sql

### Index concepts for searching, and update patient counts in the concept hierarchy ###
echo "$(date +%T): running 'post_concept_creation_tasks.sql'"
sqlcmd -E -S $MSDW2_SERVER -i post_concept_creation_tasks.sql

### Run kdestroy so Kerberos ticket doesn't interfere with DBeaver operation ###
echo "$(date +%T): running kdestroy"
kdestroy

echo "$(date +%Y-%m-%d\ %T): finishing 'update_leaf.sh'"
