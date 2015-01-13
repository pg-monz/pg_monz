#!/bin/bash
#===============================================================================
#  GLOBAL DECLARATIONS
#===============================================================================

PGSHELL_CONFDIR=$1
# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgpool_funcs.conf

TIMESTAMP_QUERY='extract(epoch from now())::int'

#===============================================================================
#  MAIN SCRIPT
#===========================================================================
psql -h $PGPOOLHOST -p $PGPOOLPORT -U $PGPOOLROLE $PGPOOLDBNAME -c "select 1" > /dev/null  2>&1;echo $?
