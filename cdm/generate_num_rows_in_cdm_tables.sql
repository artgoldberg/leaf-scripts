WITH health_data_schema_ids AS 
   ( SELECT s.schema_id
    FROM sys.schemas s
    INNER JOIN sys.sysusers u
        on u.uid = s.principal_id
    WHERE u.name = 'dbo' and s.name <> 'dbo' )

-- SELECT 'SELECT ''' + sys.schemas.name + '.' + sys.objects.name + ''', COUNT(*) FROM ' + sys.schemas.name + '.' + sys.objects.name + ';'
SELECT 'INSERT INTO #TableRowCounts VALUES(''' + sys.schemas.name + '.' + sys.objects.name + 
	''', (SELECT COUNT(*) FROM ' + sys.schemas.name + '.' + sys.objects.name + '));'
FROM sys.objects, sys.schemas
WHERE sys.objects.schema_id IN (SELECT schema_id FROM health_data_schema_ids) AND
	type_desc IN ('VIEW', 'USER_TABLE') AND
	sys.schemas.schema_id = sys.objects.schema_id
