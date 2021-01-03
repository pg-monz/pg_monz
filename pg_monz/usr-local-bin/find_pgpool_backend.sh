#!/bin/sh

# Get list of pgpool-II database backend name which you want to monitor.

PGPOOLSHELL_CONFDIR="$1"

POOL_STATUS="show pool_status"

# Load the pgpool connection option parameters.
. $PGPOOLSHELL_CONFDIR/pgpool_funcs.conf

config=$(psql -A --field-separator=',' -h $PGPOOLHOST -p $PGPOOLPORT -U $PGPOOLROLE -d $PGPOOLDATABASE -t -X -c "${POOL_STATUS}" 2>&1)
if [ $? -ne 0 ]; then
	echo "$config"
	exit
fi

replication_mode=`echo "$config" | awk -F, '$1 ~ /replication_mode/ {print $2}'`

if [ $replication_mode == 1 ]; then
	MODE=replication
else
	master_slave_mode=`echo "$config" | awk -F, '$1 ~ /master_slave_mode/ {print $2}'`
	if [ $master_slave_mode == 1 ]; then
		MODE=`echo "$config" | awk -F, '$1 ~ /master_slave_sub_mode/ {print $2}'`
	else
		MODE=connection_pool
	fi
fi

echo "{\"data\":[{\"{#MODE}\":\"$MODE\"} ]}"
