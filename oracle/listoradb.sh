#/bin/bash
# File: listoradb.sh
# Version: 1.0
# Function: To list all the parameters and information in an Oracle database. The ORACLE_SID needs to be in /etc/oratab.
#
#set -x

print_err_msg()
{
   echo "Usage: $0 ORACLE_SID ";
   echo -e "\nList of ORACLE_SID defined in /etc/oratab:"
   awk -F: '/^[^#]/ { print $1 }' /etc/oratab | uniq
   echo -e "\nList of ORACLE_HOME in /etc/oratab:"
   awk -F: '/^[^#]/ { print $2 }' /etc/oratab | uniq
}

[ $# -ne 1 ] && { print_err_msg ; exit 1; }

ORACLE_SID=$1
Found=`grep "^${ORACLE_SID}:" /etc/oratab | awk -F':' '{printf $2}'`
if [ "$Found" == "" ] ; then
   echo "Unable to proceed as the ORACLE_SID ( ${ORACLE_SID} ) is not in /etc/oratab !!"
   exit 0
else
   export ORACLE_SID=$1 ; ORAENV_ASK=NO ; . oraenv >/dev/null ; unset ORAENV_ASK
fi

if ! [ -x "$(command -v bc)" ]; then
  echo 'Error: bc is not installed.' >&2
  echo 'Please install bc on the host. On CentOS host, yum -y install bc'
  exit 1
fi
if ! [ -x "$(command -v awk)" ]; then
  echo 'Error: awk is not installed.' >&2
  exit 1
fi

#
## Function retrieve the value in v$parameter table based on the argument passed to it
#
populate_from_v_parameter () {
rc=$(sqlplus -s "/ as sysdba" << EOS
   set pages 0 feed off verify off head off echo off;
   select value from v\$parameter where name='$1';
   exit;
EOS
)
echo $rc
}

#
## Function to query from v$table
#
find_from_v_table()
{
rc=$(sqlplus -s "/ as sysdba" << EOS
   set pages 0 feed off verify off head off echo off;
   select $1 from v\$$2;
   exit;
EOS
)
echo $rc
}

#
## M A I N
#
echo -e "\nInstance Information:\n---------------------"

inststrg=$(sqlplus -s "/ as sysdba" << EOS
  set pages 0 feed off verify off head off echo off;
  select instance_name || '^' || to_char(startup_time,'DD-MM-YYYY HH24:MI') || '^' || database_status from v\$instance;
  exit;
EOS
)

echo "Instance Name: `echo $inststrg | awk -F'^' '{ print $1 }'` "
echo "Started On: `echo $inststrg | awk -F'^' '{ print $2 }'` "
echo "Database Status: `echo $inststrg | awk -F'^' '{ print $3 }'` "

v_processes=$( populate_from_v_parameter "processes" )
echo "Number of processes: $v_processes"

v_sga_max_size=$( populate_from_v_parameter "sga_max_size" )

v_sga_max_size_int=`expr $v_sga_max_size + 0`
v_sga_max_size_mb=`expr $v_sga_max_size_int / 1048576`
v_sga_max_size_gb=`expr $v_sga_max_size_int / 1073741824`
if [ $v_sga_max_size_gb -gt 0 ] ; then
  echo "Size of SGA in GB: $v_sga_max_size_gb ( $v_sga_max_size_mb MB  ) "
else
  echo "Size of SGA in MB: $v_sga_max_size_mb "
fi

echo -e "\nDatabase Information:\n---------------------"

dbstrg=$(sqlplus -s "/ as sysdba" << EOS
   set pages 0 feed off verify off head off echo off;
   select name || '^' || to_char(created,'DD-MM-YYYY HH24:MI') || '^' || log_mode || '^' || open_mode || '^' || current_scn from v\$database;
   exit;
EOS
)
echo "Database Name: `echo $dbstrg | awk -F'^' '{ print $1 }'` "
echo "Created On: `echo $dbstrg | awk -F'^' '{ print $2 }'` "
echo "ArchiveLog Mode: `echo $dbstrg | awk -F'^' '{ print $3 }'` "
echo "Open Mode: `echo $dbstrg | awk -F'^' '{ print $4 }'` "
echo "Current SCN: `echo $dbstrg | awk -F'^' '{ print $5 }'` "


dbsizestrg=$(sqlplus -s "/ as sysdba" << EOS
   set pages 0 feed off verify off head off echo off;
   select round(sum(bytes)/1048576,2) || '^' || round(sum(bytes)/1073741824,2) || '^' || round(sum(bytes)/1099511627776,2) from v\$datafile;
   exit;
EOS
)

v_dbsize_mb=`expr $(echo $dbsizestrg | awk -F'^' '{ print $1 }'|bc) `
v_dbsize_gb=`expr $(echo $dbsizestrg | awk -F'^' '{ print $2 }'|bc) `
v_dbsize_tb=`expr $(echo $dbsizestrg | awk -F'^' '{ print $3 }'|bc) `

if [ $(echo "0 < $v_dbsize_tb"|bc) -eq 1 ] ; then
  echo "Size of DB in TB: $v_dbsize_tb ( $v_dbsize_gb GB  ) "
else
  if [ $(echo "0 < $v_dbsize_gb"|bc) -eq 1 ] ; then
    echo "Size of DB in GB: $v_dbsize_gb ( $v_dbsize_mb MB ) "
  else
    echo "Size of DB in MB: $v_dbsize_mb "
  fi
fi

v_tscount=$(sqlplus -s "/ as sysdba" << EOS
   set pages 0 feed off verify off head off echo off;
   select count(tablespace_name) from dba_tablespaces;
   exit;
EOS
)
printf "Number of tablespaces : %s\n" $v_tscount

v_dfcount=$( find_from_v_table "count(name)" datafile )
printf "Number of datafiles (excluding TEMP): %s\n" $v_dfcount

v_tdfcount=$( find_from_v_table "count(name)" tempfile )
printf "Number of TEMP datafiles : %s\n" $v_tdfcount

v_targetstor=$( find_from_v_table "distinct substr(name,1,1)" datafile )
if [ "$v_targetstor" == "+" ] ; then
   echo "Database files location is on: ASM"
else
   echo "Database files location is on: FileSystem"
fi

v_spfile=$( populate_from_v_parameter "spfile" )
echo "Location of the spfile: $v_spfile"

bctstrg=$(sqlplus -s "/ as sysdba" << EOS
   set pages 0 feed off verify off head off echo off;
   select status || '^' || filename from v\$block_change_tracking;
   exit;
EOS
)

bctstatus=`echo $bctstrg | awk -F'^' '{ print $1 }'`
echo "Status of Block Change Tracking: $bctstatus"
if [ "$bctstatus" == "ENABLED" ] ; then
   echo "Location of Block Change Tracking file: `echo $bctstrg | awk -F'^' '{ print $2 }'` "
fi

v_background_dump_dest=$( populate_from_v_parameter "background_dump_dest" )
echo "Background_dump_dest: $v_background_dump_dest"

echo -e "\nOracle DB Objects Information:\n------------------------------"

tablist=$(sqlplus -s "/ as sysdba" << EOS
   set pages 0 feed off verify off head off echo off;
   select owner || '^' || count(*) from dba_tables group by owner order by 1;
   exit;
EOS
)

echo -e "A) Number of objects for each user in the database:\n"
printf "%02s %-15s %s\n" "CNT" "OWNER" "# TABLES"
printf "%02s %-15s %s\n" "===" "=====" "========"
ii=0
for item in $tablist ; do
   let ii=ii+1
   v_user=`echo $item | awk -F'^' '{ print $1 }'`
   v_cnt=`echo $item | awk -F'^' '{ print $2 }'`
   printf "%02d. %-15s %8s\n" $ii $v_user $v_cnt
done

tspacelist=$(sqlplus -s "/ as sysdba" << EOS
   set pages 0 feed off verify off head off echo off;
   select b.tablespace_name || '^' || round(tbs_size,2) || '^' || round(a.free_space,2) from
      (select tablespace_name, round(sum(bytes)/1024/1024/1024,1) as free_space
      from dba_free_space group by tablespace_name UNION
      select tablespace_name, round((free_space)/1024/1024/1024,1) as free_space 
      from dba_temp_free_space) a, (select tablespace_name, sum(bytes)/1024/1024/1024 as tbs_size from dba_data_files group by tablespace_name UNION
      select tablespace_name, sum(bytes)/1024/1024/1024 tbs_size from dba_temp_files group by tablespace_name ) b where a.tablespace_name(+)=b.tablespace_name;
   exit;
EOS
)

ii=0
echo -e "\nB) Space Utilisation based on tablespaces\n"
printf "%02s. %25s %10s %10s \n" "CNT" "TABLESPACE NAME" "SIZE GB" "FREE GB"
printf "%02s. %25s %10s %10s \n" "===" "===============" "=======" "======="
for item in $tspacelist ; do
   let ii=ii+1
   v_tsname=`echo $item | awk -F'^' '{ print $1 }'`
   v_size_gb=`echo $item | awk -F'^' '{ print $2 }'`
   v_free_gb=`echo $item | awk -F'^' '{ print $3 }'`
   printf "%02d. %25s %10s %10s %10s %10s\n" $ii $v_tsname $v_size_gb $v_free_gb
done

exit 0