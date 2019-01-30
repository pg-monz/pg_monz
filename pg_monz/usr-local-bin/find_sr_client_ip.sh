#!/bin/bash

PGSHELL_CONFDIR="$1"

GETTABLE="select row_to_json(t) from (select client_addr as \"{#SRCLIENT}\" from pg_stat_replication) as t"

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

result=$(psql -h $PGHOST -p $PGPORT -U $PGROLE -d $PGDATABASE -t -X -c "${GETTABLE}" 2>&1)
if [ $? -ne 0 ]; then
	echo "$result"
	exit
fi

IFS=$'\n'
for row in $result; do
	sr_client_list="$sr_client_list,"${row# }
done
echo '{"data":['${sr_client_list#,}' ]}'
