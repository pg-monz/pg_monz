#!/bin/bash
#===============================================================================
#  GLOBAL DECLARATIONS
#===============================================================================
APP_NAME="$1"
PGSHELL_CONFDIR="$2"
HOST_NAME="$3"
ZABBIX_AGENTD_CONF="$4"

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

TIMESTAMP_QUERY='extract(epoch from now())::int'

#===============================================================================
#  MAIN SCRIPT
#===============================================================================
case "$APP_NAME" in
	pg.stat_replication)
		sending_data=$(psql -A --field-separator=' ' -t -h $PGHOST -p $PGPORT -U $PGROLE $PGDATABASE -c  \
			"select * from ( \
			select '\"$HOST_NAME\"', 'psql.write_diff['||host(client_addr)||']', $TIMESTAMP_QUERY, pg_xlog_location_diff(sent_location, write_location) as value from pg_stat_replication \
			union all \
			select '\"$HOST_NAME\"', 'psql.replay_diff['||host(client_addr)||']', $TIMESTAMP_QUERY, pg_xlog_location_diff(sent_location, replay_location) as value from pg_stat_replication \
			union all \
			select '\"$HOST_NAME\"', 'psql.sync_priority['||host(client_addr)||']', $TIMESTAMP_QUERY, sync_priority as value from pg_stat_replication \
			) as t where value is not null \
			")
		;;
	pg.sr.status)
		sending_data=$(psql -A --field-separator=' ' -t -h $PGHOST -p $PGPORT -U $PGROLE $PGDATABASE -c  \
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
                        SELECT '\"$HOST_NAME\"','psql.confl_deadlock[' || datname || ']',$TIMESTAMP_QUERY,confl_deadlock from pg_stat_database_conflicts where datname not in ('template1','template0') \
                        ")
		;;
	*)
		echo "'$APP_NAME' did not match anything." >&2
		;;
esac

if [ $? -ne 0 ]; then
	# psql command failed.
	echo 3
	exit
fi

if [ -n "$sending_data" ]; then
	echo "$sending_data" | zabbix_sender -c $ZABBIX_AGENTD_CONF -T -i - &>/dev/null
fi

if [ $? -ne 0 ]; then
	# zabbix_sender command failed.
	echo 2
	exit
fi

# pgsql_funcs.sh was succeeded.
echo 1
