#!/bin/bash
#===============================================================================
#  GLOBAL DECLARATIONS
#===============================================================================

PGSHELL_CONFDIR="$1"
# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgsql_funcs.conf

#===============================================================================
#  MAIN SCRIPT
#===========================================================================
psql -A -t -h $PGHOST -p $PGPORT -U $PGROLE $DBNAME -c "select pg_is_in_recovery()::int" 2> /dev/null

if [ $? != 0 ]; then
 echo 0
fi
