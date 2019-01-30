#!/bin/bash

PGSHELL_CONFDIR="$1"

# For using this rules, you set the status to enable from
# [Configuration]->[Hosts]->[Discovery]->[DB and Table Name List]
# at Zabbix WEB.

# Get list of Database Name which you want to monitor.
# The default settings are excepted template databases(template0/template1).
#
# :Customize Example
#
# For "foo" and "bar" databases, set the GETDB as
# GETDB="select datname from pg_database where datname in ('foo','bar');"

GETDB="select datname from pg_database where datistemplate = 'f';"

# Get List of Table Name
# Using the default setting, Zabbix make a discovery "ALL" user tables.
# If you want to specify the tables, you can change the $GETTABLE query.
#
# :Customize Example
#
# For pgbench tables, set the GETTABLE as
#GETTABLE="select \
#            row_to_json(t) \
#          from (
#            select current_database() as "{#DBNAME}\",schemaname as \"{#SCHEMANAME}\",tablename as \"{#TABLENAME}\" \
#            from \
#              pg_tables \
#            where \
#              schemaname not in ('pg_catalog','information_schema') \
#            and \
#              tablename in ('pgbench_accounts','pgbench_branches','pgbench_history','pgbench_tellers') \
#           ) as t"

GETTABLE="select row_to_json(t) from (select current_database() as \"{#DBNAME}\",schemaname as \"{#SCHEMANAME}\",tablename as \"{#TABLENAME}\" from pg_tables where schemaname not in ('pg_catalog','information_schema')) as t"

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

# This low level discovery rules are disabled by deafult.
dbname_list=$(psql -h $PGHOST -p $PGPORT -U $PGROLE -d $PGDATABASE -t -X -c "${GETDB}" 2>&1)
if [ $? -ne 0 ]; then
	echo "$dbname_list"
	exit
fi

IFS=$'\n'
for dbname in $dbname_list; do
	tablename_list=$(psql -h $PGHOST -p $PGPORT -U $PGROLE -d ${dbname# } -t -X -c "${GETTABLE}" 2>&1)
	if [ $? -ne 0 ]; then
		echo "$tablename_list"
		exit
	fi
	for tablename in $tablename_list; do
		dblist="$dblist,"${tablename# }
	done
done
echo '{"data":['${dblist#,}' ]}'
