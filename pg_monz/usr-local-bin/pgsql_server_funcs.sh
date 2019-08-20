#!/bin/bash
#===============================================================================
#  GLOBAL DECLARATIONS
#===============================================================================
APP_NAME="$1"
PGSHELL_CONFDIR="$2"
HOST_NAME="$3"
ZABBIX_AGENTD_CONF="$4"
PARAM1="$5"

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

# Script required GNU sed which is not always the default so need to use gsed instead
LOCALGSED="sed"
gsed --version 2> /dev/null | grep -q "GNU"
if [ $? -eq 0 ]; then
	LOCALGSED="gsed"
fi

TIMESTAMP_QUERY='extract(epoch from now())::int'

PGVERSION=$(psql -A -t -X -h $PGHOST -p $PGPORT -U $PGROLE $PGDATABASE -c 'select * from version()' | cut -d ' ' -f 2 | $LOCALGSED -n 's/^\([0-9]\+\(\.[0-9]\+\)\?\).*$/\1/p')

# If the expected bc is not found, for exemple on Solaris/SmartOS, switch to awk
bc --version > /dev/null 2>&1
if [ $? -eq 0 ]; then
	if [ `echo "$PGVERSION >= 10.0" | bc` -eq 1 ] ; then
		CONN_COND="where backend_type = 'client backend'"
		LOCK_COND="and wait_event_type like '%Lock%'"
	elif [ `echo "$PGVERSION >= 9.6" | bc` -eq 1 ] ; then
		CONN_COND=''
		LOCK_COND="where wait_event_type like '%Lock%'"
	else
		CONN_COND=''
		LOCK_COND="where waiting = 'true'"
	fi
else
	CONN_COND=$(awk -v PGVERSION=$PGVERSION 'BEGIN {
		if ( PGVERSION >= 10.0 )
		{ print "where backend_type = '"'"'client backend'"'"'" }
			else if ( PGVERSION >= 9.6 )
			{ print "" }
			else { print "" }
		}')

	LOCK_COND=$(awk -v PGVERSION=$PGVERSION 'BEGIN {
		if ( PGVERSION >= 10.0 )
		{ print "and wait_event_type like '"'"'%Lock%'"'"'" }
			else if ( PGVERSION >= 9.6 )
			{ print "where wait_event_type like '"'"'%Lock%'"'"'" }
			else { print "where waiting = '"'"'true'"'"'" }
		}')
fi

#===============================================================================
#  MAIN SCRIPT
#===============================================================================
case "$APP_NAME" in
	pg.transactions)
		sending_data=$(psql -A --field-separator=' ' -t -X -h $PGHOST -p $PGPORT -U $PGROLE $PGDATABASE -c  \
						"select '\"$HOST_NAME\"', 'psql.tx_commited', $TIMESTAMP_QUERY, (select sum(xact_commit) from pg_stat_database) \
						union all \
						select '\"$HOST_NAME\"', 'psql.tx_rolledback', $TIMESTAMP_QUERY, (select sum(xact_rollback) from pg_stat_database) \
						union all \
						select '\"$HOST_NAME\"', 'psql.active_connections', $TIMESTAMP_QUERY, (select count(*) from pg_stat_activity where state = 'active') \
						union all \
						select '\"$HOST_NAME\"', 'psql.server_connections', $TIMESTAMP_QUERY, (select count(*) from pg_stat_activity $CONN_COND) \
						union all \
						select '\"$HOST_NAME\"', 'psql.idle_connections', $TIMESTAMP_QUERY, (select count(*) from pg_stat_activity where state = 'idle') \
						union all \
						select '\"$HOST_NAME\"', 'psql.idle_tx_connections', $TIMESTAMP_QUERY, (select count(*) from pg_stat_activity where state = 'idle in transaction') \
						union all \
						select '\"$HOST_NAME\"', 'psql.locks_waiting', $TIMESTAMP_QUERY, (select count(*) from pg_stat_activity $CONN_COND $LOCK_COND) \
						union all \
						select '\"$HOST_NAME\"', 'psql.server_maxcon', $TIMESTAMP_QUERY, (select setting::int from pg_settings where name = 'max_connections')" 2>&1
					)
		;;
	pg.bgwriter)
		sending_data=$(psql -A --field-separator=' ' -t -X -h $PGHOST -p $PGPORT -U $PGROLE $PGDATABASE -c \
						"select '\"$HOST_NAME\"', 'psql.buffers_alloc', $TIMESTAMP_QUERY, (select buffers_alloc from pg_stat_bgwriter) \
						union all \
						select '\"$HOST_NAME\"', 'psql.buffers_backend', $TIMESTAMP_QUERY, (select buffers_backend from pg_stat_bgwriter) \
						union all \
						select '\"$HOST_NAME\"', 'psql.buffers_backend_fsync' , $TIMESTAMP_QUERY, (select buffers_backend_fsync from pg_stat_bgwriter) \
						union all \
						select '\"$HOST_NAME\"', 'psql.buffers_checkpoint', $TIMESTAMP_QUERY, (select buffers_checkpoint from pg_stat_bgwriter) \
						union all \
						select '\"$HOST_NAME\"', 'psql.buffers_clean', $TIMESTAMP_QUERY, (select buffers_clean from pg_stat_bgwriter) \
						union all \
						select '\"$HOST_NAME\"', 'psql.checkpoints_req', $TIMESTAMP_QUERY, (select checkpoints_req from pg_stat_bgwriter) \
						union all \
						select '\"$HOST_NAME\"', 'psql.checkpoints_timed', $TIMESTAMP_QUERY, (select checkpoints_timed from pg_stat_bgwriter) \
						union all \
						select '\"$HOST_NAME\"', 'psql.maxwritten_clean', $TIMESTAMP_QUERY, (select maxwritten_clean from pg_stat_bgwriter)" 2>&1
					)
		;;
	pg.slow_query)
		sending_data=$(psql -A --field-separator=' ' -t -X -h $PGHOST -p $PGPORT -U $PGROLE $PGDATABASE -c \
						"select '\"$HOST_NAME\"', 'psql.slow_dml_queries', $TIMESTAMP_QUERY, (select count(*) from pg_stat_activity where state = 'active' and now() - query_start > '$PARAM1 sec'::interval and query ~* '^(insert|update|delete)') \
						union all \
						select '\"$HOST_NAME\"', 'psql.slow_queries', $TIMESTAMP_QUERY, (select count(*) from pg_stat_activity where state = 'active' and now() - query_start > '$PARAM1 sec'::interval) \
						union all \
						select '\"$HOST_NAME\"', 'psql.slow_select_queries', $TIMESTAMP_QUERY, (select count(*) from pg_stat_activity where state = 'active' and now() - query_start > '$PARAM1 sec'::interval and query ilike 'select%')" 2>&1
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
