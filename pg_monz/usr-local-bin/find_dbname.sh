#!/bin/bash

# Get list of Database Name which you want to monitor.
# The default settings are excepted template databases(template0/template1).
#
# :Example
#
# If you want to monitor "foo" and "bar" databases, you set the GETDB as
# GETDB="select datname from pg_database where datname in ('foo','bar');"

PGSHELL_CONFDIR="$1"

GETDB="select datname from pg_database where datistemplate = 'f';"

# Load the pgsql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

result=$(psql -h $PGHOST -p $PGPORT -U $PGROLE -d $PGDATABASE -t -X -c "${GETDB}" 2>&1)
if [ $? -ne 0 ]; then
	echo "$result"
	exit
fi

IFS=$'\n'
for dbname in $result; do
    dblist="$dblist,"'{"{#DBNAME}":"'${dbname# }'"}'
done
echo '{"data":['${dblist#,}' ]}'
