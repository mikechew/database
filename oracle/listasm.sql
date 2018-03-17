set lines 200
set pages 500
col name format a15
col path format a25
select PATH from v$asm_disk where group_number in (select group_number from v$asm_diskgroup where name in upper(<'disk group name','disk group name') ) order by group_number