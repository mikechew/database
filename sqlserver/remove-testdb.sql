USE master;
GO

IF (DB_ID('TESTDB')) IS NOT NULL
    DROP DATABASE TESTDB;
GO
