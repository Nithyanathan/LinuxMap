#!/bin/bash

username="akundnani"

check_script() {
    cat /tmp/get-info.sh
    isscript=${?}
    cat /tmp/servers.txt
    isserverlist=${?}
}

check_script;
if [$isscript -ne 0]; then
    echo "Script not found under /tmp. Check again"
    exit 1
elif [$isserverlist -ne 0]; then
    echo "Server list not found under /tmp. Check again"
    exit 1
else
    mkdir -p /tmp/cloudmo/

    for host in `cat /tmp/servers.txt`; do
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $username@$host "bash -s" < /tmp/get-info.sh &
    done
    wait
fi