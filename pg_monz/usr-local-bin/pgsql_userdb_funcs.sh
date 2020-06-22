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
	pg.size)
		sending_data=$(psql -A --field-separator=' ' -t -X -h $PGHOST -p $PGPORT -U $PGROLE $DBNAME -c  \
						"select '\"$HOST_NAME\"', 'psql.db_size[$DBNAME]', $TIMESTAMP_QUERY, (select pg_database_size('$DBNAME')) \
						union all \
						select '\"$HOST_NAME\"', 'psql.db_garbage_ratio[$DBNAME]', $TIMESTAMP_QUERY, ( \
							SELECT round(100*sum( \
							CASE (a.n_live_tup+a.n_dead_tup) WHEN 0 THEN 0 \
							ELSE c.relpages*(a.n_dead_tup/(a.n_live_tup+a.n_dead_tup)::numeric) \
							END \
							)/ sum(c.relpages),2) \
							FROM \
							pg_class as c join pg_stat_all_tables as a on(c.oid = a.relid) where relpages > 0)
						union all \
						SELECT '\"$HOST_NAME\"', 'psql.db_size_detail_' || tmp.state || '[$DBNAME]', $TIMESTAMP_QUERY, COALESCE(size, 0) \
						FROM ( \
							VALUES ('data'), ('index'), ('view'), ('sequence'), ('other') \
						) AS tmp (state) \
						LEFT JOIN ( \
						SELECT CASE \
							 WHEN relkind = 'r' OR relkind = 't' THEN 'data' \
							 WHEN relkind = 'i' THEN 'index' \
							 WHEN relkind = 'v' THEN 'view' \
							 WHEN relkind = 'S' THEN 'sequence' \
							 ELSE 'other' \
						END AS state, \
						SUM(relpages::bigint * 8 * 1024) AS size \
						FROM pg_class pg, pg_namespace pgn WHERE pg.relnamespace = pgn.oid AND pgn.nspname NOT IN ('information_schema', 'pg_catalog') \
						GROUP BY state \
						) AS tmp2 \
						ON tmp.state = tmp2.state;" 2>&1
					)
		;;
	pg.scans)
		sending_data=$(psql -A --field-separator=' ' -t -X -h $PGHOST -p $PGPORT -U $PGROLE $DBNAME -c  \
						"select '\"$HOST_NAME\"', 'psql.scans_sequential[$DBNAME]', $TIMESTAMP_QUERY, (SELECT COALESCE(SUM(seq_scan), 0) AS sequential FROM pg_stat_user_tables) \
						union all \
						select '\"$HOST_NAME\"', 'psql.scans_index[$DBNAME]', $TIMESTAMP_QUERY, (SELECT COALESCE(SUM(idx_scan), 0) AS index FROM pg_stat_user_tables);" 2>&1
					)
		;;
	pg.locks)
		sending_data=$(psql -A --field-separator=' ' -t -X -h $PGHOST -p $PGPORT -U $PGROLE $DBNAME -c  \
						"SELECT '\"$HOST_NAME\"', 'psql.locks_' || tmp.mode || '[$DBNAME]', $TIMESTAMP_QUERY, COALESCE(count, 0) \
						FROM ( \
							VALUES ('accesssharelock'), ('rowsharelock'), ('rowexclusivelock'), ('shareupdateexclusivelock'), ('sharelock'), ('sharerowexclusivelock'), ('exclusivelock'), ('accessexclusivelock') \
						) AS tmp (mode) \
						LEFT JOIN ( \
							SELECT lower(mode) AS mode, count(*) AS count \
							FROM pg_locks WHERE database IS NOT NULL AND database = (SELECT oid FROM pg_database WHERE datname = '$DBNAME') \
							GROUP BY lower(mode) \
						) AS tmp2 \
						ON tmp.mode = tmp2.mode;" 2>&1
					)
		;;
	pg.querylength)
		sending_data=$(psql -A --field-separator=' ' -t -X -h $PGHOST -p $PGPORT -U $PGROLE $DBNAME -c  \
						"SELECT '\"$HOST_NAME\"', 'psql.querylength_query[$DBNAME]', $TIMESTAMP_QUERY, COALESCE(max(extract(epoch FROM CURRENT_TIMESTAMP - query_start)), 0) FROM pg_stat_activity WHERE state NOT LIKE 'idle%' AND datname = '$DBNAME'
						UNION ALL
						SELECT '\"$HOST_NAME\"', 'psql.querylength_transaction[$DBNAME]', $TIMESTAMP_QUERY, COALESCE(max(extract(epoch FROM CURRENT_TIMESTAMP - xact_start)), 0) FROM pg_stat_activity WHERE datname = '$DBNAME';" 2>&1
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
response=$(echo "$result" | awk -F ';' '$1 ~ /^(info|sent)/ && match($1,/[0-9].*$/) {sum+=substr($1,RSTART,RLENGTH)} END {print sum}')
if [ -n "$response" ]; then
	echo "$response"
else
	echo "$result"
fi
