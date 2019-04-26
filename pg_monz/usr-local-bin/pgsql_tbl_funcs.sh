#!/bin/bash

APP_NAME="$1"
PGSHELL_CONFDIR="$2"
HOST_NAME="$3"
ZABBIX_AGENTD_CONF="$4"
DBNAME="$5"
SCHEMANAME="$6"
TABLENAME="$7"

TIMESTAMP_QUERY='extract(epoch from now())::int'

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

case "$APP_NAME" in
	pg.stat_table)
		sending_data=$(psql -A --field-separator=' ' -t -X -h $PGHOST -p $PGPORT -U $PGROLE $DBNAME -c \
						"select '\"$HOST_NAME\"', 'psql.table_analyze_count[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select analyze_count from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.table_autoanalyze_count[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select autoanalyze_count from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.table_autovacuum_count[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select autovacuum_count from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.table_heap_cachehit_ratio[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select CASE heap_blks_hit+heap_blks_read WHEN 0 then 100 else round(heap_blks_hit*100/(heap_blks_hit+heap_blks_read), 2) end from pg_statio_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.table_idx_cachehit_ratio[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select CASE WHEN idx_blks_read is NULL then 0 when idx_blks_hit+idx_blks_read=0 then 100 else round(idx_blks_hit*100/(idx_blks_hit+idx_blks_read + 0.0001), 2) end from pg_statio_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.table_n_dead_tup[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select n_dead_tup from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.table_n_tup_del[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select n_tup_del from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.table_n_tup_hot_upd[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select n_tup_hot_upd from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.table_idx_scan[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select coalesce(idx_scan,0) from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.table_seq_tup_read[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select coalesce(seq_tup_read,0) from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.table_idx_tup_fetch[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select coalesce(idx_tup_fetch,0) from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.table_n_tup_ins[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select n_tup_ins from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.table_n_live_tup[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select n_live_tup from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.table_seq_scan[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select seq_scan from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.table_n_tup_upd[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select n_tup_upd from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
						union all \
						select '\"$HOST_NAME\"', 'psql.table_vacuum_count[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select vacuum_count from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME')
						union all \
						select '\"$HOST_NAME\"', 'psql.table_garbage_ratio[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select round(100*(CASE (n_live_tup+n_dead_tup) WHEN 0 THEN 0 ELSE (n_dead_tup/(n_live_tup+n_dead_tup)::numeric) END),2) from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME')
						union all \
						select '\"$HOST_NAME\"', 'psql.table_total_size[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select pg_total_relation_size('${SCHEMANAME}.\"${TABLENAME}\"'))" 2>&1
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
