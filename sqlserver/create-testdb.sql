USE master;	
GO

CREATE DATABASE TESTDB ON  PRIMARY 
( NAME = N’TESTDB_D’, FILENAME = N’D:\DATA\TESTDB.mdf’ , 
SIZE = 2048KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N’TESTDB_L’, FILENAME = N’D:\DATA\TESTDB.ldf’ , 
SIZE = 512KB , MAXSIZE = 512KB , FILEGROWTH = 10%)
GO

USE TESTDB;
GO
ALTER DATABASE TESTDB SET RECOVERY FULL
GO

CREATE TABLE [dbo].Dept 
(
Deptno int,
DName varchar(14),
Loc varchar(13) 
)
GO

Insert into [dbo].Dept values (10, ‘Sales’, ‘New York’);
Insert into [dbo].Dept values (20, ‘Engineering’, ‘Boston’);
SELECT Deptno, Dname, Loc from [dbo].Dept;
GO
