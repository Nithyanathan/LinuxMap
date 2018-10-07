#!/bin/bash

username="akundnani"
password="Microsoft~123"

check_script() {
  cat /tmp/get-info.sh
  isscript=${?}
  cat /tmp/servers.txt
  isserverlist=${?}
}

check_script;
if [$isscript -ne 0]; then
    echo "Script get-info.sh not found under /tmp location, please copy script and try again"
elif [$isserverlist -ne 0]; then
    echo "Server list servers.txt not found under /tmp location, please create servers.txt and try again"
else
    #Create folder for files
    mkdir -p /tmp/cloudmo/

    for host in `cat /tmp/servers.txt`; do
        ssh $username@$host $password "bash -s" < /tmp/get-info.sh &
    done
    wait
fi