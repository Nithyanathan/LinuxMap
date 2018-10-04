#!/bin/bash

hostname=`sudo uname -n`
location="/tmp/$hostname.sysinfo.txt"
packagecsv="/tmp/$hostname.packages.csv"


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
    if [ $iscentos -eq 0 || $isredhat -eq 0];then
        #check if yum is installed
        if [ -x "$(command -v yum)" ]; then
            sudo yum list installed >> $location
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
    cat /var/opt/oracle/oratab >> $location
}

get_web($isapache) {
    echo "================================================================" >> $location
    echo "8> Web Server Name" >> $location
    if [ $isapache -eq 0 ]
    then
        sudo cat /etc/apache2/apache2.conf | grep 'ServerName' >> $location
    else
        sudo cat /etc/httpd/httpd.conf | grep 'ServerName' >> $location
    fi
    echo "9> Web Sites Configured" >> $location
    echo "10> Web Site Root Path" >> $location
}

get_fileshare() {
    echo "11> NFS and CIFS shares information " >> $location
    echo "================================================================" >> $location
    sudo cat /proc/mounts | grep nfs  >> $location
    sudo cat /etc/fstab | grep nfs  >> $location
    sudo cat /proc/mounts | grep cifs  >> $location
    sudo cat /etc/fstab | grep cifs  >> $location
}

#Check OS Version details
check_os() {
    grep ubuntu /proc/version > /dev/null 2>&1
    isubuntu=${?}
    grep centos /proc/version > /dev/null 2>&1
    iscentos=${?}
    grep suse /proc/version > /dev/null 2>&1
    issuse=${?}
    grep 'Red Hat' /proc/version > /dev/null 2>&1
    isredhat=${?}
}

#Check if Oracle is installed
check_oracle() {
    cat /var/opt/oracle/oratab > /dev/null 2>&1
    isoracle=${?}    
}

#Check web service installed
check_web() {
    sudo netstat -tulpen | egrep '80|443' > /dev/null 2>&1
    echo "================================================================" >> $location
    if [ -x "$(command -v apachectl)" ]; then
            sudo apachectl -S >> $location
            isapache=${?}
    elif [ -x "$(command -v apache2ctl)" ]; then
            sudo apache2ctl -S >> $location
            isapache=${?}
    else        
            echo "No apache installation detected" >> $location
    fi
    isweb=${?}
}

#Check file share configured
check_fileshare() {
    sudo cat /etc/fstab | egrep 'nfs|cifs' > /dev/null 2>&1
    isfileshare=${?}
}

check_os;
if [ $iscentos -ne 0 ] && [ $isubuntu -ne 0 ] && [$issuse -ne 0] && [$isredhat -ne 0];
then
    echo "unsupported operating system."
    exit 1 
else
    get_info;
fi

check_oracle;
if [ $isoracle -ne 0];
then
    exit 1
else
    get_oracle;
fi

check_fileshare;
if [ $isfileshare -ne 0];
then
    exit 1
else
    get_fileshare;
fi

echo "================================================================"

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