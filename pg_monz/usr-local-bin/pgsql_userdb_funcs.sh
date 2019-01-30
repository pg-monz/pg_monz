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
							pg_class as c join pg_stat_all_tables as a on(c.oid = a.relid) where relpages > 0)" 2>&1
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
