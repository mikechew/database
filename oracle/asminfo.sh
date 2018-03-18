#!/bin/ksh
# File: asminfo.sh
# script to list ASM disk groups, ASM disks and mapping of ASM DG/Linux devices.
set +x

asmsid=`ps -efa | grep asm_pmon | grep "[_]pmon[_]" | while read -r line ; do printf '%s\n' ${line##*_pmon_} ; done`

## check if the asm_pmon process is running on this host. For RAC environment, the +ASM instance
## will appear as +ASM1, +ASM2 instead of +ASM.
if [ -z $asmsid ] ; then printf "ASM instance is not runnng" ; exit ; else printf "$asmsid is up and running\n" ; fi

echo " "
echo "List of ASM diskgroups and related information:"
echo "==============================================="
export ORACLE_SID=$asmsid
export ORAENV_ASK=NO
. oraenv >/dev/null 2>/dev/null

sqlplus -S / as sysasm <<EOF
set echo off
set feedback off
col group_number format 99999 heading GROUP
col name format a15
col total_gb format 99990.99
col free_gb format 99990.99

select group_number, name, total_mb/1024 total_gb, free_mb/1024 free_gb from v\$asm_diskgroup;
exit
EOF

echo " "
echo "List of ASM disks related information:"
echo "======================================"
sqlplus -S / as sysdba <<EOF
set echo off
set feedback off
set linesize 400
col name format a16
col path format a60
col group_number format 9999 head GRP#
col disk_number format 9999 head DSK#
col udid format a4
col label format a8
col total_gb format 99990.99
col free_gb format 99990.99
col read_time  format 9999990.99
col write_time format 9999990.99

select group_number, disk_number, mode_status, total_mb/1024 total_gb, free_mb/1024 free_gb, state, mount_date, bytes_read, bytes_written, read_time, write_time, label, name, path from v\$asm_disk;
exit
EOF

echo " "
echo "List of mapping of ASM disks to Linux devices:"
echo "=============================================="
 
for ff in `/etc/init.d/oracleasm listdisks`
do
devpath=`/etc/init.d/oracleasm querydisk -p $ff | head -2 | grep /dev | awk -F: '{print $1}'`
echo "$ff: $devpath"
done
