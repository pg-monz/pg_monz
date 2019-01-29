#!/bin/bash

# Get status of pgpool-II database backend which you want to monitor.

APP_NAME="$1"
PGPOOLSHELL_CONFDIR="$2"
HOST_NAME="$3"
ZABBIX_AGENTD_CONF="$4"

BACKENDDB="show pool_nodes"
TIME=` date +%s`

# Load the pgpool connection option parameters.
source $PGPOOLSHELL_CONFDIR/pgpool_funcs.conf

IFS=$'\n'

case "$APP_NAME" in
	pgpool.nodes)
		pool_nodes=$(psql -A --field-separator=',' -h $PGPOOLHOST -p $PGPOOLPORT -U $PGPOOLROLE -d $PGPOOLDATABASE -t -X -c "${BACKENDDB}" 2>&1)

		if [ $? -ne 0 ]; then
			echo "$pool_nodes"
			exit
		fi

		sending_data=$(for backendrecord in $pool_nodes; do
							BACKENDID=`echo $backendrecord | awk -F, '{print $1}'`
							BACKENDNAME=`echo $backendrecord | awk -F, '{print $2}'`
							BACKENDPORT=`echo $backendrecord | awk -F, '{print $3}'`
							BACKEND=ID_${BACKENDID}_${BACKENDNAME}_${BACKENDPORT}
							BACKENDSTATE=`echo $backendrecord | awk -F, '{print $4}'`
							BACKENDWEIGHT=`echo $backendrecord | awk -F, '{print $5}'`
							BACKENDROLE=`echo $backendrecord | awk -F, '{print $6}'`
							BACKENDREPLICATIONDELAY=`echo $backendrecord | awk -F, '{print $9}'`
							BACKENDLASTSTATUSCHANGE=`echo $backendrecord | awk -F, '{print $10}'`
							echo -e "\"$HOST_NAME\" pgpool.backend.status[${BACKEND}] $TIME $BACKENDSTATE"
							echo -e "\"$HOST_NAME\" pgpool.backend.weight[${BACKEND}] $TIME $BACKENDWEIGHT"
							echo -e "\"$HOST_NAME\" pgpool.backend.role[${BACKEND}] $TIME $BACKENDROLE"
							if [ ! -z "$BACKENDREPLICATIONDELAY" ]; then
							    echo -e "\"$HOST_NAME\" pgpool.backend.replication_delay[${BACKEND}] $TIME $BACKENDREPLICATIONDELAY"
							fi
							if [ ! -z "$BACKENDLASTSTATUSCHANGE" ]; then
							    echo -e "\"$HOST_NAME\" pgpool.backend.last_status_change[${BACKEND}] $TIME $BACKENDLASTSTATUSCHANGE"
							fi
						done
					)
		;;
	*)
	echo "'$APP_NAME' did not match anything."
	exit
	;;
esac

result=$(echo "$sending_data" | zabbix_sender -c $ZABBIX_AGENTD_CONF -v -T -i - 2>&1)
response=$(echo "$result" | awk -F ';' '$1 ~ /^info/ && match($1,/[0-9].*$/) {sum+=substr($1,RSTART,RLENGTH)} END {print sum}')
if [ -n "$response" ]; then
	echo "$response"
else
	echo "$result"
fi
