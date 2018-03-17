set linesize 400
col name format a16
col path format a60
col group_number format 9999 head GRP#
col disk_number format 9999 head DSK#
col udid format a4
col label format a8

select group_number, disk_number, mode_status, total_mb, free_mb, state, mount_date, bytes_read, bytes_written, read_time, write_time, label, udid, name, path from v$asm_disk;