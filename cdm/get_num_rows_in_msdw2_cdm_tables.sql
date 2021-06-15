-- make temp table for row counts
IF OBJECT_ID(N'tempdb..#TableRowCounts') IS NOT NULL
	DROP TABLE #TableRowCounts
CREATE TABLE #TableRowCounts(
	[TableName] NVARCHAR(200),
	[RowCount] INT);

-- stored PROC to count records & store count in temp table
IF OBJECT_ID('tempdb..#CountRows') IS NOT NULL
BEGIN
    DROP PROC #CountRows
END
GO

CREATE PROCEDURE #CountRows
	@CountsSchemaName NVARCHAR(200),
 	@CountsTableOrViewName NVARCHAR(200),
	@TempTable NVARCHAR(200)
AS
BEGIN
    DECLARE @FullyQualifiedTableOrViewName NVARCHAR(200)
    SET @FullyQualifiedTableOrViewName = CONCAT( @CountsSchemaName, '.', @CountsTableOrViewName )
    DECLARE @sql NVARCHAR(400) = CONCAT('INSERT INTO ',
						    			@TempTable,
						    			' VALUES(',
						    			CONCAT('''', @FullyQualifiedTableOrViewName, ''''),
						    			', ',
						    			'(SELECT COUNT(*) FROM ',
						    			@FullyQualifiedTableOrViewName,
						    			'))'
						    			)
    PRINT CONVERT(NVARCHAR(200), GETDATE()) + ': ' + @sql
    EXEC (@sql)
END
GO

-- make temp table for all schema name and object name pairs
IF OBJECT_ID(N'tempdb..#TableSchemaAndTVs') IS NOT NULL
	DROP TABLE #TableSchemaAndTVs
CREATE TABLE #TableSchemaAndTVs(
	[RowId] INT IDENTITY(1,1) PRIMARY KEY,
	[SchemaName] NVARCHAR(200),
	[ObjectName] NVARCHAR(200));

-- select schemas to count
WITH health_data_schema_ids AS 
   (SELECT s.schema_id
    FROM sys.schemas s
    INNER JOIN sys.sysusers u
        on u.uid = s.principal_id
    WHERE u.name = 'dbo' and s.name <> 'dbo')

INSERT INTO #TableSchemaAndTVs (SchemaName, ObjectName)
SELECT sys.schemas.name, sys.objects.name
FROM sys.objects, sys.schemas
WHERE sys.objects.schema_id IN (SELECT schema_id FROM health_data_schema_ids) AND
	type_desc IN ('VIEW', 'USER_TABLE') AND
	sys.schemas.schema_id = sys.objects.schema_id

-- Loop through all schema name and object name pairs, saving row count
DECLARE @row_id INT     = 1
DECLARE @max_row_id INT = (SELECT MAX(RowId) FROM #TableSchemaAndTVs)
PRINT '@max_row_id: ' + CONVERT(NVARCHAR(200), @max_row_id)
DECLARE @schema_name NVARCHAR(200)
DECLARE @object_name NVARCHAR(200)

WHILE @row_id <= @max_row_id
BEGIN
  SELECT @schema_name = SchemaName, @object_name = ObjectName
  FROM #TableSchemaAndTVs
  WHERE RowId = @row_id

  PRINT CONVERT(NVARCHAR(200), @row_id) + ': ' + @schema_name + '.' + @object_name
  EXEC #CountRows @CountsSchemaName = @schema_name, @CountsTableOrViewName = @object_name, @TempTable = '#TableRowCounts'

  SET @row_id += 1
END

SELECT * FROM #TableRowCounts