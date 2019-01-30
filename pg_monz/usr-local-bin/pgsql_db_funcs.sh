#!/bin/bash

APP_NAME="$1"
PGSHELL_CONFDIR="$2"
HOST_NAME="$3"
ZABBIX_AGENTD_CONF="$4"
DBNAME="$5"

TIMESTAMP_QUERY='extract(epoch from now())::int'

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

case "$APP_NAME" in
	pg.stat_database)
		sending_data=$(psql -A --field-separator=' ' -t -X -h $PGHOST -p $PGPORT -U $PGROLE $PGDATABASE -c \
						"select '\"$HOST_NAME\"', 'psql.db_connections[$DBNAME]', $TIMESTAMP_QUERY, (select numbackends from pg_stat_database where datname = '$DBNAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.cachehit_ratio[$DBNAME]', $TIMESTAMP_QUERY, (SELECT round(blks_hit*100/(blks_hit+blks_read), 2) AS cache_hit_ratio FROM pg_stat_database WHERE datname = '$DBNAME' and blks_read > 0 union all select 0.00 AS cache_hit_ratio order by cache_hit_ratio desc limit 1) \
						union all \
						select '\"$HOST_NAME\"', 'psql.db_tx_commited[$DBNAME]', $TIMESTAMP_QUERY, (select xact_commit from pg_stat_database where datname = '$DBNAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.db_deadlocks[$DBNAME]', $TIMESTAMP_QUERY, (select deadlocks from pg_stat_database where datname = '$DBNAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.db_tx_rolledback[$DBNAME]', $TIMESTAMP_QUERY, (select xact_rollback from pg_stat_database where datname = '$DBNAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.db_temp_bytes[$DBNAME]', $TIMESTAMP_QUERY, (select temp_bytes from pg_stat_database where datname = '$DBNAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.db_deleted[$DBNAME]', $TIMESTAMP_QUERY, (select tup_deleted from pg_stat_database where datname = '$DBNAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.db_fetched[$DBNAME]', $TIMESTAMP_QUERY, (select tup_fetched from pg_stat_database where datname = '$DBNAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.db_inserted[$DBNAME]', $TIMESTAMP_QUERY, (select tup_inserted from pg_stat_database where datname = '$DBNAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.db_returned[$DBNAME]', $TIMESTAMP_QUERY, (select tup_returned from pg_stat_database where datname = '$DBNAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.db_updated[$DBNAME]', $TIMESTAMP_QUERY, (select tup_updated from pg_stat_database where datname = '$DBNAME')" 2>&1
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
