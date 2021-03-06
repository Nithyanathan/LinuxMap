######################################################################################
## Author: Cloud Modernization - Delivery <CloudMo-Delivery@microsoft.com>
## Version: 0.2 	Date: 10/4/2018
######################################################################################

############### Starting of the script ###############################################
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
        echo "Running get-info.sh script on $host"
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $username@$host "bash -s" < /tmp/get-info.sh
    done
    for host in `cat /tmp/servers.txt`; do
        echo "Copying files from $host to /tmp/cloudmo"
        scp $username@$host:/tmp/cloudmo* /tmp/cloudmo/
    done
fi

echo "Scan complete, please copy /tmp/cloudmo files to your local machine for analysis."