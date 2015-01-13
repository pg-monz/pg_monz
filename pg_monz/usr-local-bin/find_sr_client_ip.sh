#!/bin/bash

PGSHELL_CONFDIR="$1"
HOST_GROUP="$2"

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

GETTABLE="select row_to_json(t) from (select 'streaming' as \"{#MODE}\", client_addr as \"{#SRCLIENT}\", '$HOST_GROUP' as \"{#HOST_GROUP}\" from pg_stat_replication) as t"

for row in $(psql -h $PGHOST -p $PGPORT -U $PGROLE -d $PGDATABASE -t -c "${GETTABLE}"); do
	sr_client_list="$sr_client_list,"$row
done

echo '{"data":['${sr_client_list#,}' ]}'
