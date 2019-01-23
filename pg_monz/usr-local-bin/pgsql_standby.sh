#!/bin/bash

PGSHELL_CONFDIR="$1"

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

result=$(psql -A -t -h $PGSTANDBY -p $PGPORT -U $PGROLE -d $PGDATABASE -c "select pg_is_in_recovery()::int" 2>&1)
echo "$result"
