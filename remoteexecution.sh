#!/bin/bash

username=xxxx
password=xxxx

for host in `cat /tmp/servers.txt`; do
    ssh $username@$host $password "bash -s" < ./backup.sh &
done
wait