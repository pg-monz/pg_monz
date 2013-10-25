#!/bin/bash

# This low level discovery rules are disabled by deafult.
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

for dbname in $(psql -h $1 -p $2 -U $3 -d $4 -t -c "${GETDB}"); do
    for tablename in $(psql -h $1 -p$2 -U $3 -d $dbname -t -c "${GETTABLE}"); do
    dblist="$dblist,"$tablename
    done
done
echo '{"data":['${dblist#,}' ]}'
