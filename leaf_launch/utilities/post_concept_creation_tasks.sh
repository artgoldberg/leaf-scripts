#!/bin/bash
# run the Leaf stored procedures after concepts are created and/or updated
# password must be entered manually

echo "$(date '+%Y-%m-%d %H:%M'): starting 'post_concept_creation_tasks.sh'"
sqlcmd -S msdw2-mssql-prd.msnyuhealth.org -U sql_svc_leaf -i post_concept_creation_tasks.sql
echo "$(date '+%Y-%m-%d %H:%M'): finished 'post_concept_creation_tasks.sh'"
