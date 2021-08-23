bcp test_database.dbo.Persons out test.out -U SA -c -S localhost
bcp rpt.LEAF_SCRATCH.Persons out test.out -U sql_svc_leaf -c -S msdw2-mssql-dv2.msnyuhealth.org

