#!/bin/bash

hostname=`sudo uname -n`
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
    echo "1> BIOS and Serial Information " >> $location
    echo "================================================================" >> $location
    sudo dmidecode | grep -i bios  >> $location
    sudo dmidecode | egrep -A10 "System Information" >> $location
    echo "================================================================" >> $location
    echo "2> Disk Info and Disk Layout "  >> $location
    echo "================================================================" >> $location
    sudo lvmdiskscan >> $location
    sudo fdisk -l|grep /dev/sd  >> $location
    echo "================================================================" >> $location
    echo "3> Block Device Details:"  >> $location
    echo "================================================================" >> $location
    sudo lsblk >> $location
    echo "================================================================" >> $location
    echo "4> File System Disk Usage:"  >> $location
    echo "================================================================" >> $location
    sudo df -hT >> $location
    echo "================================================================" >> $location
    echo "5> Current Patch level of the System " >> $location
    echo "================================================================" >> $location
    sudo uname -a|awk -F ' ' '{print $3}' >> $location
    echo "================================================================" >> $location
    echo "6> List of Packages" >> $location
    echo "================================================================" >> $location
    if [ $iscentos -eq 0 ];then
        #check if yum is installed
        if [ -x "$(command -v yum)" ]; then
            sudo yum list installed >> $location
            echo "NAME,VERSION,RELEASE" > $packagecsv
            sudo rpm -qa --queryformat "%{NAME},%{VERSION},%{RELEASE}\n" | sort -t\; -k 1 >> $packagecsv
        else
            sudo rpm -qa >> $location
            echo "NAME,VERSION,RELEASE" > $packagecsv
            sudo rpm -qa --queryformat "%{NAME},%{VERSION},%{RELEASE}\n" | sort -t\; -k 1 >> $packagecsv
        fi
    elif [ $isubuntu -eq 0 ];then
        sudo dpkg -l >> $location
        echo "Name,Version,Section,Homepage,Source" > $packagecsv
        sudo dpkg-query -Wf '${Package},${Version},${Section},${Homepage},${Source}\n' | sort >> $packagecsv
    elif [ $issuse -eq 0 ];then
        zypper se --installed-only -s >> $location
    else
        echo "ERROR:No suitable package manager was found." >> $location
    fi
}

get_oracle() {
    echo "================================================================" >> $location
    echo "7> List of Oracle Databases" >> $location
    cat /etc/oratab >> $location
}

get_web() {
    echo "================================================================" >> $location
    if [ -x "$(command -v apachectl)" ]; then
        echo "8> Apache Configuration" >> $location
        sudo apachectl -S >> $location
    elif [ -x "$(command -v apache2ctl)" ]; then
        echo "8> Apache Configuration" >> $location
        sudo apache2ctl -S >> $location
    else        
        echo "================================================================" >> $location
        echo "8> Web Server Configuration" >> $location
        sudo httpd -S >> $location
    fi
}

get_fileshare() {
    echo "================================================================" >> $location
    echo "9> NFS and CIFS shares information " >> $location    
    sudo cat /proc/mounts | grep nfs  >> $location
    sudo cat /etc/fstab | grep nfs  >> $location
    sudo cat /proc/mounts | grep cifs  >> $location
    sudo cat /etc/fstab | grep cifs  >> $location
}

get_cluster() {
    echo "================================================================" >> $location
    echo "10> Cluster Information  " >> $location    
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
    sudo yum list installed | grep oracle > /dev/null 2>&1
    isoracle=${?}
    if [ $isubuntu -eq 0 ];then
        sudo dpkg -l | grep mysql-server > /dev/null 2>&1
        ismysql=${?}
    else
        sudo yum list installed | grep mysql > /dev/null 2>&1
        ismysql=${?}
    fi
}

#Check web service installed
check_web() {
    sudo netstat -tulpen | egrep ':80|:443' > /dev/null 2>&1
    isweb=${?}
}

#Check file share configured
check_fileshare() {
    sudo cat /etc/fstab | egrep 'nfs|cifs' > /dev/null 2>&1
    isfileshare=${?}
}

#Check if cluster is configured
check_cluster() {
    if [ -x "$(command -v pcs)" ]; then
        iscluster=${?}
    fi
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
    echo "7> No Database configured " >> $location
elif [ -x "$(command -v mysql)" ]; then
    echo "================================================================" >> $location
    echo "7> MySql Database Configured: Collect MySql database inventory manually" >> $location
else
    get_oracle;
fi

check_web;
if [$isweb -ne 0]; then
    echo "No Web Applications found"
    echo "================================================================" >> $location
    echo "8> No Web Applications configured" >> $location
else
    get_web;
fi

check_fileshare;
if [ $isfileshare -ne 0 ]; then
    echo "No file share found."
    echo "================================================================" >> $location
    echo "9> No file share deployed " >> $location
else
    get_fileshare;
fi

if [ -x "$(command -v pcs)" ]; then
    get_cluster;
else
    echo "No cluster configuration using pcs found."
    echo "================================================================" >> $location
    echo "10> No Cluster configuration found using pcs" >> $location
fi

echo "================================================================"
echo "================================================================" >> $location
echo "11> Computer Hardware Information" >> $location
echo " installig PIP moudle for for python package management"
sudo curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
sudo python get-pip.py
echo "pip installed suessfully"
*******************************************

echo "installing hwinfo package using PIP"
sudo pip install python-hwinfo

echo "getting hardware information of the machine "
sudo hwinfo >> $location

echo "================================================================"
echo "Please copy/export content of: $location & $packagecsv and share with Microsoft Engagement Team."