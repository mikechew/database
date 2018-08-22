#/bin/bash
#set -x
#set -o nounset
#set -o errexit

readonly numparms=1

usage () 
{
  echo -e "\n  usage: $0 Oracle_SID \nexample: $0 vbigdb \n\n queries the Oracle database and list all system related info \n" >&2; exit 1;
}

[ $# -ne $numparms ] && usage 

ORACLE_SID=$1
Found=`grep "^${ORACLE_SID}:" /etc/oratab | awk -F':' '{printf $2}'`
if [ "$Found" == "" ] ; then
   echo "Unable to proceed as the ORACLE_SID ( ${ORACLE_SID} ) is not in /etc/oratab !!"
   exit 0
else
   export ORACLE_SID=$1 ; ORAENV_ASK=NO ; . oraenv >/dev/null ; unset ORAENV_ASK
fi

sqlplus -s "/ as sysdba" << EOS
  set pagesize 100
  set linesize 100
  set echo off
  set feedback off
  set wrap on
  col tablespace_name format a15
  col file_name format a75
  select distinct tablespace_name, file_name from dba_data_files order by 1;
  select owner,count(*) from dba_tables group by owner order by 1;
  select dbid, name, open_mode from v\$database;
  select sum(bytes)/(1024*1024*1024) "dbSize (GB)" from dba_data_files;
  select * from v\$instance;
  exit;
EOS
