#! /usr/bin/env bash
# comment: use command ./run_leaf_omop_scripts.sh
# run the leaf-scripts
# An active Kerberos ticket for service_leaf must be available to run sqlcmd -E

MSDW2_PROD=msdw2-mssql-prd.msnyuhealth.org

echo "Starting 'run_leaf_omop_scripts.sh' at $(date)"
echo "Running '1_sqlsets.sql'"
sqlcmd -E -S $MSDW2_PROD -i 1_sqlsets.sql
echo "Running '2_demographics.sql'"
sqlcmd -E -S $MSDW2_PROD -i 2_demographics.sql
echo "Running '3_visits.sql'"
sqlcmd -E -S $MSDW2_PROD -i 3_visits.sql
# echo "Running '4_labs.sql'"
# sqlcmd -E -S $MSDW2_PROD -i 4_labs.sql
echo "Running '5_vitals.sql'"
sqlcmd -E -S $MSDW2_PROD -i 5_vitals.sql
# echo "Running '8_other.sql'"
# sqlcmd -E -S $MSDW2_PROD -i 8_other.sql

# echo "Running 'post_concept_creation_tasks.sql'"
# sqlcmd -E -S $MSDW2_PROD -i post_concept_creation_tasks.sql
echo "Finishing 'run_leaf_omop_scripts.sh' at $(date)"
