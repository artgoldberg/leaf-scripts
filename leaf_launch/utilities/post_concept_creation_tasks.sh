#!/bin/bash
# run the Leaf stored procedures after concepts are created and/or updated
# password must be entered manually
# run with nohup

echo "$(date '+%Y-%m-%d %H:%M'): starting 'post_concept_creation_tasks.sh'" >> post_concept_creation_tasks.log
sqlcmd -S msdw2-mssql-prd.msnyuhealth.org -U sql_svc_leaf -i post_concept_creation_tasks.sql >> post_concept_creation_tasks.log
echo "$(date '+%Y-%m-%d %H:%M'): finished 'post_concept_creation_tasks.sh'" >> post_concept_creation_tasks.log
