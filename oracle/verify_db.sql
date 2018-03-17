set pagesize 100
set linesize 100
set echo off
set feedback off
set wrap on
col tablespace_name format a15
col file_name format a75
select distinct tablespace_name, file_name from dba_data_files order by 1;
select owner,count(*) from dba_tables group by owner order by 1;
select dbid, name, open_mode from v$database;
select sum(bytes)/(1024*1024*1024) "dbSize (GB)" from dba_data_files;
select * from v$instance;
