/*
 *  Since Sinai’s Population Health folks load non-Clarity data to some Caboodle tables,
 *  where _HasSourceClarity or _IsDeleted are defined, filter caboodle data to
 *  tbl._HasSourceClarity = 1 and tbl._IsDeleted = 0
 */
USE src;

select TABLE_NAME, COLUMN_NAME from information_schema.columns
where table_name IN (SELECT t.name 
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE s.name = N'caboodle')
  AND COLUMN_NAME IN ('_HasSourceClarity', '_IsDeleted')
ORDER BY TABLE_NAME, COLUMN_NAME;
