#!/bin/bash

PGSHELL_CONFDIR="$1"

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

psql -t -X -A -h $PGHOST -p $PGPORT -U $PGROLE -d $PGDATABASE -c "select 1" 2>/dev/null
if [ $? -ne 0 ]; then
	echo 0
fi
