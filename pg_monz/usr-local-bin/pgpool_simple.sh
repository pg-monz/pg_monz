#!/bin/bash

PGSHELL_CONFDIR="$1"

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgpool_funcs.conf

psql -t -A -h $PGPOOLHOST -p $PGPOOLPORT -U $PGPOOLROLE $PGPOOLDBNAME -c "select 1" 2>/dev/null
if [ $? -ne 0 ]; then
	echo 0
fi
