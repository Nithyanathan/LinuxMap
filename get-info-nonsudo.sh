######################################################################################
## Author: Cloud Modernization - Delivery <CloudMo-Delivery@microsoft.com>
## Version: 0.2 	Date: 10/4/2018
## The script is used to collect following information from Rehat/Centos Linux System
## 1. BIOS and Serial Information
## 2. Disk Info and Disk Layout  
## 3. Block Device Details
## 4. File System and Disk Usage
## 5. Current Patching Level of the system
## 6. Serial Information
######################################################################################
###############  How to use this script file  ########################################
##  1. Copy the file and rename get-info.sh
##  2. If permission denies set the execute permission using the below commands 
##      chmod u+x get-info.sh 
##  3. Check using the command: ls -l get-info.sh to check the permission applied
##  4. Create a file as Output.txt file at /tmp direcotry which contains output 
##  5. Execute the command on going to location 
##      [root@mcdphlputl1502 ~]# ./get-info.sh 
##  6. Check the package for executing Mailx command: rpm -q redhat-lsb
######################################################################################

############### Starting of the script ###############################################

#!/bin/bash

hostname=`uname -n`
location="/tmp/cloudmo-$hostname.sysinfo.txt"
packagecsv="/tmp/cloudmo-$hostname.packages.csv"


get_info() {
    echo "================================================================" > $location
    echo -e "* System Name: \t` hostname`" >> $location
    echo -e "* System Domain Name: \t`dnsdomainname`" >> $location
    echo -e "* Generated on: \t\t`date`" >> $location
    echo -e "* Running as: \t\t\t`whoami`" >> $location      
    echo "================================================================" >> $location
    echo " Ouput of Server : $hostname" >> $location
    echo "================================================================" >> $location
    echo "1> BIOS and System Information " >> $location
    echo "================================================================" >> $location
    dmesg | grep "DMI:" | cut -c "6-" | cut -d "," -f "2"  >> $location
    dmesg | grep "DMI:" | cut -c "6-" | cut -d "," -f "1" >> $location
    echo "================================================================" >> $location
    echo "2> Amount of Physical Memory: " >> $location
    dmesg | grep "Memory:" | cut -d '/' -f '2-' | cut -d ' ' -f '1' >> $location
    echo "================================================================" >> $location
    ## Requires Sudo - echo "3> Disk Info and Disk Layout "  >> $location
    ## Requires Sudo - echo "================================================================" >> $location
    ## Requires Sudo - sudo lvmdiskscan >> $location
    ## Requires Sudo - sudo fdisk -l|grep /dev/sd  >> $location
    ## Requires Sudo - echo "================================================================" >> $location
    echo "3> Block Device Details:"  >> $location
    echo "================================================================" >> $location
    lsblk >> $location
    echo "================================================================" >> $location
    echo "4> File System Disk Usage:"  >> $location
    echo "================================================================" >> $location
    df -hT >> $location
    echo "================================================================" >> $location
    echo "5> Current Patch level of the System " >> $location
    echo "================================================================" >> $location
    uname -a|awk -F ' ' '{print $3}' >> $location
    echo "================================================================" >> $location
    echo "6> IP Configuration of machine" >> $location
    ip -o addr | awk '!/^[0-9]*: ?lo|link\/ether/ {print $2" "$4}' >> $location
    echo "================================================================" >> $location
    echo "7> List of Packages" >> $location
    echo "================================================================" >> $location
    if [ $iscentos -eq 0 ];then
        #check if yum is installed
        if [ -x "$(command -v yum)" ]; then
            yum list installed >> $location
            echo "NAME,VERSION,RELEASE" > $packagecsv
            rpm -qa --queryformat "%{NAME},%{VERSION},%{RELEASE}\n" | sort -t\; -k 1 >> $packagecsv
        else
            rpm -qa >> $location
            echo "NAME,VERSION,RELEASE" > $packagecsv
            rpm -qa --queryformat "%{NAME},%{VERSION},%{RELEASE}\n" | sort -t\; -k 1 >> $packagecsv
        fi
    elif [ $isubuntu -eq 0 ];then
        dpkg -l >> $location
        echo "Name,Version,Section,Homepage,Source" > $packagecsv
        dpkg-query -Wf '${Package},${Version},${Section},${Homepage},${Source}\n' | sort >> $packagecsv
    elif [ $issuse -eq 0 ];then
        zypper se --installed-only -s >> $location
    else
        echo "ERROR:No suitable package manager was found." >> $location
    fi
}

get_oracle() {
    echo "================================================================" >> $location
    echo "8> List of Oracle Databases" >> $location
    cat /etc/oratab >> $location
}

get_mysql() {
    echo "Enter MySQL admin Username"
    read -p "MySQL UserName: " mysqluser
    echo "Enter MySQL admin Password"
    read -s -p "MySQL Password: " mysqlpass
    echo "================================================================" >> $location
    echo "8> List of MySQL Databases" >> $location
    mysql -u $mysqluser -p$mysqlpass -e "show databases;" >> $location
}

get_web() {
    echo "================================================================" >> $location
    if [ -x "$(command -v apachectl)" ]; then
        echo "9> Apache Configuration" >> $location
        apachectl -S >> $location
    elif [ -x "$(command -v apache2ctl)" ]; then
        echo "9> Apache Configuration" >> $location
        apache2ctl -S >> $location
    else        
        echo "================================================================" >> $location
        echo "9> Web Server Configuration" >> $location
        httpd -S >> $location
    fi
}

get_fileshare() {
    echo "================================================================" >> $location
    echo "10> NFS and CIFS shares information " >> $location    
    cat /proc/mounts | grep nfs  >> $location
    cat /etc/fstab | grep nfs  >> $location
    cat /proc/mounts | grep cifs  >> $location
    cat /etc/fstab | grep cifs  >> $location
}

get_cluster() {
    echo "================================================================" >> $location
    echo "11> Cluster Information  " >> $location    
    pcs status >> $location
    pcs cluster status >> $location
    pcs status resources >> $location
}


check_os() {
    grep ubuntu /proc/version > /dev/null 2>&1
    isubuntu=${?}
    grep centos /proc/version > /dev/null 2>&1
    iscentos=${?}
    grep suse /proc/version > /dev/null 2>&1
    issuse=${?}
    grep 'Red Hat' /proc/version > /dev/null 2>&1
    iscentos=${?}
}

#Check if database is installed
check_db() {
    yum list installed | grep oracle > /dev/null 2>&1
    isoracle=${?}
    if [ $isubuntu -eq 0 ];then
        dpkg -l | grep mysql-server > /dev/null 2>&1
        ismysql=${?}
    else
        yum list installed | grep mysql > /dev/null 2>&1
        ismysql=${?}
    fi
}

#Check web service installed
check_web() {
    netstat -tulpen | egrep ':80|:443' > /dev/null 2>&1
    isweb=${?}
}

#Check file share configured
check_fileshare() {
    cat /etc/fstab | egrep 'nfs|cifs' > /dev/null 2>&1
    isfileshare=${?}
}

check_os;
if [ $iscentos -ne 0 ] && [ $isubuntu -ne 0 ] && [$issuse -ne 0];
then
    echo "unsupported operating system."
else
    get_info;
fi

check_db;
if [ $isoracle -ne 0 ] && [$ismysql -ne 0]; then
    echo "No database found"
    echo "================================================================" >> $location
    echo "8> No Database configured " >> $location
elif [ -x "$(command -v mysql)" ]; then
    get_mysql;
else
    get_oracle;
fi

check_web;
if [$isweb -ne 0]; then
    echo "No Web Applications found"
    echo "================================================================" >> $location
    echo "9> No Web Applications configured" >> $location
else
    get_web;
fi

check_fileshare;
if [ $isfileshare -ne 0 ]; then
    echo "No file share found."
    echo "================================================================" >> $location
    echo "10> No file share deployed " >> $location
else
    get_fileshare;
fi

if [ -x "$(command -v pcs)" ]; then
    get_cluster;
else
    echo "================================================================" >> $location
    echo "11> No cluster configured on given node." >> $location    
fi

echo "================================================================"
echo "================================================================" >> $location
## Requires Sudo - echo "13> Computer Hardware Information" >> $location
## Requires Sudo - echo " installig PIP moudle for for python package management"
## Requires Sudo - curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
## Requires Sudo - sudo python get-pip.py
## Requires Sudo - echo "pip installed suessfully"
## Requires Sudo - *******************************************

## Requires Sudo - echo "installing hwinfo package using PIP"
## Requires Sudo - sudo pip install python-hwinfo

## Requires Sudo - echo "getting hardware information of the machine "
## Requires Sudo - sudo hwinfo >> $location

## Requires Sudo - echo "================================================================"
echo "Please copy/export content of: $location & $packagecsv and share with Microsoft Engagement Team."