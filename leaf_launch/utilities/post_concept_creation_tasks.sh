#!/bin/bash
# run the Leaf stored procedures after concepts are created and/or updated
# An active Kerberos ticket for service_leaf must be availalbe to run sqlcmd
# run using "nohup ./post_concept_creation_tasks.sh &"

echo "$(date '+%Y-%m-%d %H:%M'): starting 'post_concept_creation_tasks.sh'" >> post_concept_creation_tasks.log
echo "$(date '+%Y-%m-%d %H:%M'): starting 'post_concept_creation_tasks.sh'" >> post_concept_creation_tasks_error.log
sqlcmd -E -S msdw2-mssql-prd.msnyuhealth.org -U sql_svc_leaf -i ../../omop/5.3/post_concept_creation_tasks.sql >> post_concept_creation_tasks.log 2>> post_concept_creation_tasks_error.log
echo "$(date '+%Y-%m-%d %H:%M'): finished 'post_concept_creation_tasks.sh'" >> post_concept_creation_tasks.log
echo "$(date '+%Y-%m-%d %H:%M'): finished 'post_concept_creation_tasks.sh'" >> post_concept_creation_tasks_error.log
