#!/bin/bash

PGSHELL_CONFDIR="$1"

GETROW="select count(*) from pg_stat_replication"

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

result=$(psql -h $PGHOST -p $PGPORT -U $PGROLE -d $PGDATABASE -t -X -c "$GETROW" 2>&1)
if [ $? -ne 0 ]; then
	echo "$result"
	exit
fi

if [ $result -ge 1 ]; then
	echo '{"data":[{"{#MODE}":"streaming"} ]}'
else
	echo '{"data":[ ]}'
fi
