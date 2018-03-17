col compatibility format a10
col database_compatibility format a10
col name format a15
set linesize 200
col total_gb format 99099.99
col free_gb format 99099.99
select group_number, name, type, total_mb, total_mb/1024 total_gb, free_mb, free_mb/1024 free_gb, compatibility, database_compatibility from v$asm_diskgroup;