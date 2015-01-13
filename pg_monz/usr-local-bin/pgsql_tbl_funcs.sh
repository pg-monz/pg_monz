#!/bin/bash
#===============================================================================
#  GLOBAL DECLARATIONS
#===============================================================================
APP_NAME="$1"
PGSHELL_CONFDIR="$2"
HOST_NAME="$3"
ZABBIX_SERVER="$4"
ZABBIX_TRAPPER_PORT="$5"
DBNAME="$6"
SCHEMANAME="$7"
TABLENAME="$8"

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

TIMESTAMP_QUERY='extract(epoch from now())::int'

#===============================================================================
#  MAIN SCRIPT
#===============================================================================
case "$APP_NAME" in
	pg.stat_table)
		sending_data=$(psql -A --field-separator=' ' -t -h $PGHOST -p $PGPORT -U $PGROLE $DBNAME -c  \
			"select '$HOST_NAME', 'psql.table_analyze_count[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select analyze_count from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
			union all \
			select '$HOST_NAME', 'psql.table_autoanalyze_count[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select autoanalyze_count from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
			union all \
			select '$HOST_NAME', 'psql.table_autovacuum_count[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select autovacuum_count from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
			union all \
			select '$HOST_NAME', 'psql.table_heap_cachehit_ratio[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select CASE heap_blks_hit+heap_blks_read WHEN 0 then 100 else round(heap_blks_hit*100/(heap_blks_hit+heap_blks_read), 2) end from pg_statio_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
			union all \
			select '$HOST_NAME', 'psql.table_idx_cachehit_ratio[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select CASE WHEN idx_blks_read is NULL then 0 when idx_blks_hit+idx_blks_read=0 then 100 else round(idx_blks_hit*100/(idx_blks_hit+heap_blks_read + 0.0001), 2) end from pg_statio_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
			union all \
			select '$HOST_NAME', 'psql.table_n_dead_tup[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select n_dead_tup from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
			union all \
			select '$HOST_NAME', 'psql.table_n_tup_del[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select n_tup_del from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
			union all \
			select '$HOST_NAME', 'psql.table_n_tup_hot_upd[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select n_tup_hot_upd from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
			union all \
			select '$HOST_NAME', 'psql.table_idx_scan[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select coalesce(idx_scan,0) from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
			union all \
			select '$HOST_NAME', 'psql.table_seq_tup_read[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select coalesce(seq_tup_read,0) from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
			union all \
			select '$HOST_NAME', 'psql.table_idx_tup_fetch[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select coalesce(idx_tup_fetch,0) from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
			union all \
			select '$HOST_NAME', 'psql.table_n_tup_ins[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select n_tup_ins from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
			union all \
			select '$HOST_NAME', 'psql.table_n_live_tup[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select n_live_tup from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
			union all \
			select '$HOST_NAME', 'psql.table_seq_scan[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select seq_scan from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
			union all \
			select '$HOST_NAME', 'psql.table_n_tup_upd[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select n_tup_upd from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME') \
			union all \
			select '$HOST_NAME', 'psql.table_vacuum_count[$DBNAME,$SCHEMANAME,$TABLENAME]', $TIMESTAMP_QUERY, (select vacuum_count from pg_stat_user_tables where schemaname = '$SCHEMANAME' and relname = '$TABLENAME')")
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

echo "$sending_data" | zabbix_sender -z $ZABBIX_SERVER -p $ZABBIX_TRAPPER_PORT -T -i - &>/dev/null

if [ $? -ne 0 ]; then
	# zabbix_sender command failed.
	echo 2
	exit
fi

# pgsql_funcs.sh was succeeded.
echo 1
