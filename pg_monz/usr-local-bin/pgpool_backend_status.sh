#!/bin/bash

# Get list of pgpool-II database backend name which you want to monitor.
#
APP_NAME="$1"
PGPOOLSHELL_CONFDIR=$2
HOST_NAME="$3"
ZABBIX_SERVER="$4"
ZABBIX_TRAPPER_PORT="$5"

source $PGPOOLSHELL_CONFDIR/pgpool_funcs.conf

BACKENDDB="show pool_nodes"
POOLSTATUS="show pool_status"
TIME=` date +%s`

case "$APP_NAME" in
         pgpool.status)
                 pool_nodes=$(psql -A --field-separator=',' -t -h $PGPOOLHOST -p $PGPOOLPORT -U $PGPOOLROLE -d $PGPOOLDATABASE -t -c "${BACKENDDB}")
                 pool_status=$(psql -A --field-separator=',' -t -h $PGPOOLHOST -p $PGPOOLPORT -U $PGPOOLROLE -d $PGPOOLDATABASE -t -c "${POOLSTATUS}")
                 delegate_ip=`echo "$pool_status" | grep delegate_IP | awk -F, '{print $2}'`
                 num_ip=`ip addr show | grep $delegate_ip | wc -l`
                 if [ $? -ne 0 ]; then
                    echo 3        exit
                 fi
     
                 sending_data=$(for backendrecord in $(echo $pool_nodes); do
                                  BACKENDID=`echo $backendrecord | awk -F, '{print $1}'`
                                  BACKENDNAME=`echo $backendrecord | awk -F, '{print $2}'`
                                  BACKENDPORT=`echo $backendrecord | awk -F, '{print $3}'`
                                  BACKEND=ID_${BACKENDID}_${BACKENDNAME}_${BACKENDPORT}
                                  BACKENDSTATE=`echo $backendrecord | awk -F, '{print $4}'`
                                  BACKENDWEIGHT=`echo $backendrecord | awk -F, '{print $5}'`
                                  BACKENDROLE=`echo $backendrecord | awk -F, '{print $6}'`
                                  echo -e "$HOST_NAME pgpool.backend.status[${BACKEND}] $TIME $BACKENDSTATE"
                                  echo -e "$HOST_NAME pgpool.backend.weight[${BACKEND}] $TIME $BACKENDWEIGHT"
                                  echo -e "$HOST_NAME pgpool.backend.role[${BACKEND}] $TIME $BACKENDROLE"
                               done
                                  echo -e "$HOST_NAME pgpool.have_delegate_ip $TIME $num_ip"                          
                               ) 
          ;;
          *)
                 echo "'$APP_NAME' did not match anything." >&2                ;;
esac

echo "$sending_data" | zabbix_sender -z $ZABBIX_SERVER -p $ZABBIX_TRAPPER_PORT -T -i - &>/dev/null
if [ $? -ne 0 ]; then        
        # zabbix_sender command failed.
        echo 2        
        exit
fi

echo 1                                                                                                     
