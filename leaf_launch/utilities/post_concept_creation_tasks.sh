#!/bin/bash
# run the Leaf stored procedures after concepts are created and/or updated
# database account password must be set in SQLCMDPASSWORD environment variable
# run using "nohup ./post_concept_creation_tasks.sh"

echo "$(date '+%Y-%m-%d %H:%M'): starting 'post_concept_creation_tasks.sh'" >> post_concept_creation_tasks.log
sqlcmd -S msdw2-mssql-prd.msnyuhealth.org -U sql_svc_leaf -i ../../omop/5.3/post_concept_creation_tasks.sql >> post_concept_creation_tasks.log
echo "$(date '+%Y-%m-%d %H:%M'): finished 'post_concept_creation_tasks.sh'" >> post_concept_creation_tasks.log
