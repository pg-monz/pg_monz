#!/bin/bash
#===============================================================================
#  GLOBAL DECLARATIONS
#===============================================================================
APP_NAME="$1"
PGSHELL_CONFDIR="$2"
HOST_NAME="$3"
ZABBIX_AGENTD_CONF="$4"
DBNAME="$5"

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

TIMESTAMP_QUERY='extract(epoch from now())::int'

#===============================================================================
#  MAIN SCRIPT
#===============================================================================
case "$APP_NAME" in
	pg.size)
		sending_data=$(psql -A --field-separator=' ' -t -h $PGHOST -p $PGPORT -U $PGROLE $DBNAME -c  \
			"select '\"$HOST_NAME\"', 'psql.db_size[$DBNAME]', $TIMESTAMP_QUERY, (select pg_database_size('$DBNAME')) \
                        union all \
			select '\"$HOST_NAME\"', 'psql.db_garbage_ratio[$DBNAME]', $TIMESTAMP_QUERY, ( \
                              SELECT round(100*sum( \
                                               CASE (a.n_live_tup+a.n_dead_tup) WHEN 0 THEN 0 \
                                               ELSE c.relpages*(a.n_dead_tup/(a.n_live_tup+a.n_dead_tup)::numeric) \
                                               END \
                                              )/ sum(c.relpages),2) \
                              FROM \
                                  pg_class as c join pg_stat_all_tables as a on(c.oid = a.relid) where relpages > 0 \
                        ) \
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

echo "$sending_data" | zabbix_sender -c $ZABBIX_AGENTD_CONF -T -i - &>/dev/null

if [ $? -ne 0 ]; then
	# zabbix_sender command failed.
	echo 2
	exit
fi

# pgsql_funcs.sh was succeeded.
echo 1
