#!/bin/bash

# Get list of pgpool-II database backend name which you want to monitor.

APP_NAME="$1"
PGPOOLSHELL_CONFDIR="$2"
HOST_NAME="$3"
ZABBIX_AGENTD_CONF="$4"

POOL="show pool_cache"
TIME=` date +%s`

# Load the pgpool connection option parameters.
source $PGPOOLSHELL_CONFDIR/pgpool_funcs.conf

case "$APP_NAME" in
	pgpool.cache)
		pool_cache=$(psql -A --field-separator=',' -h $PGPOOLHOST -p $PGPOOLPORT -U $PGPOOLROLE -d $PGPOOLDATABASE -t -X -c "${POOL}" 2>&1)

		if [ $? -ne 0 ]; then
			echo "$pool_cache"
			exit
		fi

		num_cache_hits=`echo "$pool_cache" | awk -F, '{print $1}'`
		num_selects=`echo "$pool_cache" | awk -F, '{print $2}'`
		cache_hit_ratio=`echo "$pool_cache" | awk -F, '{print $3 * 100}'`
		num_hash_entries=`echo "$pool_cache" | awk -F, '{print $4}'`
		used_hash_entries=`echo "$pool_cache" | awk -F, '{print $5}'`
		num_cache_entries=`echo "$pool_cache" | awk -F, '{print $6}'`
		used_cache_entries_size=`echo "$pool_cache" | awk -F, '{print $7}'`
		free_cache_entries_size=`echo "$pool_cache" | awk -F, '{print $8}'`
		fragment_cache_entries_size=`echo "$pool_cache" | awk -F, '{print $9}'`
		sending_data=$(
						echo -e \"$HOST_NAME\" pgpool.cache.num_cache_hits $TIME $num_cache_hits
						echo -e \"$HOST_NAME\" pgpool.cache.num_selects $TIME $num_selects
						echo -e \"$HOST_NAME\" pgpool.cache.cache_hit_ratio $TIME $cache_hit_ratio
						echo -e \"$HOST_NAME\" pgpool.cache.num_hash_entries $TIME $num_hash_entries
						echo -e \"$HOST_NAME\" pgpool.cache.used_hash_entries $TIME $used_hash_entries
						echo -e \"$HOST_NAME\" pgpool.cache.num_cache_entries $TIME $num_cache_entries
						echo -e \"$HOST_NAME\" pgpool.cache.used_cache_entries_size $TIME $used_cache_entries_size
						echo -e \"$HOST_NAME\" pgpool.cache.free_cache_entries_size $TIME $free_cache_entries_size
						echo -e \"$HOST_NAME\" pgpool.cache.fragment_cache_entries_size $TIME $fragment_cache_entries_size
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
