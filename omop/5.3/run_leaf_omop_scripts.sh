#! /usr/bin/env bash
# comment: use command ./run_leaf_omop_scripts.sh
# run the leaf-scripts
MSDW2_PROD="10.95.46.175"
LEAF_SVC_UID="sql_svc_leaf"
# LEAF_SVC_PWD must be defined in the shell environment
sqlcmd -S $MSDW2_PROD -U $LEAF_SVC_UID -P $LEAF_SVC_PWD -i 1_sqlsets.sql
sqlcmd -S $MSDW2_PROD -U $LEAF_SVC_UID -P $LEAF_SVC_PWD -i 2_demographics.sql
sqlcmd -S $MSDW2_PROD -U $LEAF_SVC_UID -P $LEAF_SVC_PWD -i 3_visits.sql
sqlcmd -S $MSDW2_PROD -U $LEAF_SVC_UID -P $LEAF_SVC_PWD -i 5_vitals.sql
sqlcmd -S $MSDW2_PROD -U $LEAF_SVC_UID -P $LEAF_SVC_PWD -i 8_other.sql

sqlcmd -S $MSDW2_PROD -U $LEAF_SVC_UID -P $LEAF_SVC_PWD -i post_concept_creation_tasks.sql