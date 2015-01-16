#!/bin/bash

# Get list of pgpool-II database backend name which you want to monitor.
#
APP_NAME="$1"
PGPOOLSHELL_CONFDIR="$2"
HOST_NAME="$3"
ZABBIX_AGENTD_CONF="$4"

source $PGPOOLSHELL_CONFDIR/pgpool_funcs.conf

POOL="show pool_pools"
TIME=` date +%s`

case "$APP_NAME" in
         pgpool.connections)
                 pool_connections=$(psql -A --field-separator=',' -t -h $PGPOOLHOST -p $PGPOOLPORT -U $PGPOOLROLE -d $PGPOOLDATABASE -t -c "${POOL}")
                 if [ $? -ne 0 ]; then
                    echo 3        exit
                 fi
                 valid_num=`echo "$pool_connections" | wc -l`
                 frontend_used=`echo "$pool_connections" | awk -F, '$12 !~ /^0$/ {print $12,$1}' | uniq | wc -l`
                 backend_used=`echo "$pool_connections" | awk -F, '$11 !~ /^0$/ {print $11}' | wc -l`
                 frontend_total=`echo "$pool_connections" | awk -F, '{print $1}' | uniq |wc -l`
                 sending_data=$(
                                 echo -e \"$HOST_NAME\" pgpool.frontend.used $TIME $frontend_used
                                 echo -e \"$HOST_NAME\" pgpool.frontend.max $TIME $frontend_total
                                 echo -e \"$HOST_NAME\" pgpool.frontend.empty $TIME $(($frontend_total - $frontend_used))
                                 echo -e \"$HOST_NAME\" pgpool.backend.used $TIME $backend_used
                                ) 
          ;;
          *)
                 echo "'$APP_NAME' did not match anything." >&2                ;;
esac
echo "$sending_data" | zabbix_sender -c $ZABBIX_AGENTD_CONF -T -i - &>/dev/null
if [ $? -ne 0 ]; then        
        # zabbix_sender command failed.
        echo 2        
        exit
fi

echo 1                                                                                                     
