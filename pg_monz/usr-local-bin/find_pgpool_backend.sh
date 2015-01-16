#!/bin/bash

# Get list of pgpool-II database backend name which you want to monitor.
#



PGPOOLSHELL_CONFDIR="$1"
source $PGPOOLSHELL_CONFDIR/pgpool_funcs.conf

POOL_STATUS="show pool_status"


config=$(psql -A --field-separator=',' -t -h $PGPOOLHOST -p $PGPOOLPORT -U $PGPOOLROLE -d $PGPOOLDATABASE -t -c "${POOL_STATUS}")

replication_mode=`echo "$config" | awk -F, '$1 ~ /replication_mode/ {print $2}'`

if [ $replication_mode == 1 ]; then

MODE=replication

else

  master_slave_mode=`echo "$config" | awk -F, '$1 ~ /master_slave_mode/ {print $2}'`

  if [ $master_slave_mode == 1 ]; then
   
     MODE=`echo "$config" | awk -F, '$1 ~ /master_slave_sub_mode/ {print $2}'`

  else
     
     MODE=connection_pool
  fi
fi

BACKENDDB="show pool_nodes"

for backendrecord in $(psql -A --field-separator=',' -t -h $PGPOOLHOST -p $PGPOOLPORT -U $PGPOOLROLE -d $PGPOOLDATABASE -t -c "${BACKENDDB}"); do
    BACKENDID=`echo $backendrecord | awk -F, '{print $1}'`
    BACKENDNAME=`echo $backendrecord | awk -F, '{print $2}'`
    BACKENDPORT=`echo $backendrecord | awk -F, '{print $3}'`
    BACKEND=ID_${BACKENDID}_${BACKENDNAME}_${BACKENDPORT}
    backendlist="$backendlist,"'{"{#MODE}":"'$MODE'","{#BACKEND}":"'$BACKEND'"}'
done
echo '{"data":['${backendlist#,}' ]}'
