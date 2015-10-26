#!/usr/bin/env bash

PGSHELL_CONFDIR="$1"

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

result=$(psql -A -t -h $PGHOST -p $PGPORT -U $PGROLE $PGDATABASE -c "select (NOT(pg_is_in_recovery()))::int" 2>&1)
echo "$result"
