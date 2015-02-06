#!/bin/bash

PGSHELL_CONFDIR="$1"

# Load the psql connection option parameters.
source $PGSHELL_CONFDIR/pgpool_funcs.conf

if [ ! -n "$PGPOOLCONF" ]; then
  echo  0
  exit
fi

if [ ! -e "$PGPOOLCONF" ]; then
  echo  0
  exit
fi

delegate_ip=`cat $PGPOOLCONF | grep delegate_IP | awk -F\' '{print $2}'` 2>/dev/null

if [ ! -n "$delegate_ip" ]; then
  echo  0
  exit
fi

num_ip=`ip addr show | grep $delegate_ip | wc -l`
echo $num_ip
