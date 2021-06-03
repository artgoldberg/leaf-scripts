# run the leaf-scripts
MSDW2_PROD="10.95.46.175:1433"
LEAF_SVC_UID="sql_svc_leaf"
# LEAF_SVC_PWD must be defined in the shell environment
sqlcmd -S $MSDW2_PROD -U $LEAF_SVC_UID -P $LEAF_SVC_PWD -i 2_demographics.sql
