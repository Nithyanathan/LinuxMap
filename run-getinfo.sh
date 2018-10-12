######################################################################################
## Author: Cloud Modernization - Delivery <CloudMo-Delivery@microsoft.com>
## Version: 0.2 	Date: 10/4/2018
##  Pre-Requisites
##  1. sshpass
######################################################################################

############### Starting of the script ###############################################
#!/bin/bash

username="akundnani"
password="********"

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
        echo "Running get-info.sh script on $host"
        sshpass -p $password ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $username@$host "bash -s" < /tmp/get-info.sh &
    done
    wait
    for host in `cat /tmp/servers.txt`; do
        echo "Copying files from $host to /tmp/cloudmo"
        sshpass -p $password scp $username@$host:/tmp/cloudmo* /tmp/cloudmo/
    done
    wait
fi

echo "Scan complete, please copy /tmp/cloudmo files to your local machine for analysis."