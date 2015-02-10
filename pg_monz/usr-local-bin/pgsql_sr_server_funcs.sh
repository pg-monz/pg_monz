#!/bin/bash

APP_NAME="$1"
PGSHELL_CONFDIR="$2"
HOST_NAME="$3"
ZABBIX_AGENTD_CONF="$4"

TIMESTAMP_QUERY='extract(epoch from now())::int'

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

case "$APP_NAME" in
	pg.stat_replication)
		sending_data=$(psql -A --field-separator=' ' -t -h $PGHOST -p $PGPORT -U $PGROLE $PGDATABASE -c \
						"select * from ( \
						select '\"$HOST_NAME\"', 'psql.write_diff['||host(client_addr)||']', $TIMESTAMP_QUERY, pg_xlog_location_diff(sent_location, write_location) as value from pg_stat_replication \
						union all \
						select '\"$HOST_NAME\"', 'psql.replay_diff['||host(client_addr)||']', $TIMESTAMP_QUERY, pg_xlog_location_diff(sent_location, replay_location) as value from pg_stat_replication \
						union all \
						select '\"$HOST_NAME\"', 'psql.sync_priority['||host(client_addr)||']', $TIMESTAMP_QUERY, sync_priority as value from pg_stat_replication \
						) as t where value is not null" 2>&1
					)
		;;
	pg.sr.status)
		sending_data=$(psql -A --field-separator=' ' -t -h $PGHOST -p $PGPORT -U $PGROLE $PGDATABASE -c \
						"select '\"$HOST_NAME\"', 'psql.block_query', $TIMESTAMP_QUERY, (select CASE count(setting) when 0 then 1 ELSE (select CASE (select pg_is_in_recovery()::int) when 1 then 1 ELSE (select CASE (select count(*) from pg_stat_replication where sync_priority > 0) when 0 then 0 else 1 END) END) END from pg_settings where name ='synchronous_standby_names' and setting !='') \
						union all \
						SELECT '\"$HOST_NAME\"','psql.confl_tablespace[' || datname || ']',$TIMESTAMP_QUERY,confl_tablespace from pg_stat_database_conflicts where datname not in ('template1','template0') \
						union all \
						SELECT '\"$HOST_NAME\"','psql.confl_lock[' || datname || ']',$TIMESTAMP_QUERY,confl_lock from pg_stat_database_conflicts where datname not in ('template1','template0') \
						union all \
						SELECT '\"$HOST_NAME\"','psql.confl_snapshot[' || datname || ']',$TIMESTAMP_QUERY,confl_snapshot from pg_stat_database_conflicts where datname not in ('template1','template0') \
						union all \
						SELECT '\"$HOST_NAME\"','psql.confl_bufferpin[' || datname || ']',$TIMESTAMP_QUERY,confl_bufferpin from pg_stat_database_conflicts where datname not in ('template1','template0') \
						union all \
						SELECT '\"$HOST_NAME\"','psql.confl_deadlock[' || datname || ']',$TIMESTAMP_QUERY,confl_deadlock from pg_stat_database_conflicts where datname not in ('template1','template0')" 2>&1
					)
		;;
	*)
		echo "'$APP_NAME' did not match anything."
		exit
		;;
esac

if [ $? -ne 0 ]; then
	echo "$sending_data"
	exit
fi

result=$(echo "$sending_data" | zabbix_sender -c $ZABBIX_AGENTD_CONF -v -T -i - 2>&1)
response=$(echo "$result" | awk -F ';' '$1 ~ /^info/ && match($1,/[0-9].*$/) {sum+=substr($1,RSTART,RLENGTH)} END {print sum}')
if [ -n "$response" ]; then
	echo "$response"
else
	echo "$result"
fi
