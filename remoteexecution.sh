#!/bin/bash

servers="serverA serverB serverC serverN"
for server in $servers; do
    ssh $server "bash -s" < ./backup.sh &
done
wait