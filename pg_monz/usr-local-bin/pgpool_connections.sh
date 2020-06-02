#!/bin/bash

# Get list of pgpool-II database backend name which you want to monitor.

APP_NAME="$1"
PGPOOLSHELL_CONFDIR="$2"
HOST_NAME="$3"
ZABBIX_AGENTD_CONF="$4"

POOL="show pool_pools"
TIME=` date +%s`

# Load the pgpool connection option parameters.
source $PGPOOLSHELL_CONFDIR/pgpool_funcs.conf

case "$APP_NAME" in
	pgpool.connections)
		pool_connections=$(psql -A --field-separator=',' -h $PGPOOLHOST -p $PGPOOLPORT -U $PGPOOLROLE -d $PGPOOLDATABASE -t -X -c "${POOL}" 2>&1)

		if [ $? -ne 0 ]; then
			echo "$pool_connections"
			exit
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
		echo "'$APP_NAME' did not match anything."
		exit
		;;
esac

result=$(echo "$sending_data" | zabbix_sender -c $ZABBIX_AGENTD_CONF -v -T -i - 2>&1)
response=$(echo "$result" | awk -F ';' '$1 ~ /^(info|sent)/ && match($1,/[0-9].*$/) {sum+=substr($1,RSTART,RLENGTH)} END {print sum}')
if [ -n "$response" ]; then
	echo "$response"
else
	echo "$result"
fi
