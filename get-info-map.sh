#!/bin/bash

hostname=`uname -n`
location="/tmp/cloudmo-$hostname.sysinfo.txt"
packagecsv="/tmp/cloudmo-$hostname.packages.csv"

#Check if database is installed
check_db() {
    if [ $isubuntu -eq 0 ];then
        dpkg-l | grep oracle > /dev/null 2>&1
        isoracle=${?}
        dpkg -l | grep mysql-server > /dev/null 2>&1
        ismysql=${?}
    else
        yum list installed | grep oracle > /dev/null 2>&1
        isoracle=${?}
        yum list installed | grep mysql > /dev/null 2>&1
        ismysql=${?}
    fi
}

#Check web service installed
check_web() {
    netstat -tulpen | egrep ':80|:443' > /dev/null 2>&1
    isweb=${?}
}

GetLinuxDistribution() {
## Parser Regex (?sxn)^(?>Distributor\ ID:\t(?'distributorId'[^\n]*)\n)(?>Description:\t(?'description'[^\n]*)\n)(?>Release:\t(?'release'[^\n]*)\n)(?>Codename:\t(?'codename'[^\n]*)\n)
    if [ -e /etc/redhat-release ];then
        iscentos=${?}
        l_patch=`uname -a|awk -F ' ' '{print $3}'` >> $location
        l_distributor=`cat /etc/redhat-release |sed s/\ release.*//`
        l_release=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
        c_codename=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
        l_description=$l_distributor' '$l_release' '$c_codename
        echo "Distributor ID: $l_distributor" >> $location
        echo "Description: $l_description" >> $location
        echo "Current Patch Level: `uname -a|awk -F ' ' '{print $3}'`" >> $location
        echo "Release: $l_release" >> $location
        echo "Codename: $c_codename" >> $location
    elif [ -e /etc/os-release ];then
        l_description=`cat /etc/os-release | sed -n -e 's/^PRETTY_NAME=\(.*\)/\1/p'`
        echo $l_description | grep -i ubuntu
        isubuntu=${?}
        echo $l_description | grep -i centos
        iscentos=${?}
        l_release=`cat /etc/os-release | sed -n -e 's/^VERSION_ID="\(.*\)"/\1/p'`
        echo "Distributor ID: $l_description" >> $location
        echo "Description: $l_description" >> $location
        echo "Current Patch Level: `uname -a|awk -F ' ' '{print $3}'`" >> $location
        echo "Release: $l_release" >> $location
        echo "Codename: $c_codename" >> $location
    else
        echo "Distributor ID: UNKNOWN" >> $location
        echo "Description: UNKNOWN" >> $location
        echo "Current Patch Level: `uname -a|awk -F ' ' '{print $3}'`" >> $location
        echo "Release: UNKNOWN" >> $location
        echo "Codename: UNKNOWN" >> $location
    fi
}

GetLinuxProcessors() {
    ## Parser Regex (?sixn)^(?>processor[ \t]*:\ (?'processor'\d+)).*?(?>\nvendor_id[ \t]*:\ (?'vendor_id'[^\n]+)).*?(?>\ncpu\ family[ \t]*:\ (?'cpu_family'\d+)).*?(?>\nmodel[ \t]*:\ (?'model'\d+)).*?(?>\nmodel\ name[ \t]*:\ (?'model_name'[^\n]+)).*?(?>\nstepping[ \t]*:\ (?'stepping'\d+)).*?(?>\ncpu\ MHz[ \t]*:\ (?'cpu_mhz'\d+)).*?(?>\ncache\ size[ \t]*:\ (?'cache_size_kb'\d+)\ KB).*?(?>(\nphysical\ id[ \t]*:\ (?'physical_id'\d+))?).*?(?>(\ncore\ id[ \t]*:\ (?'core_id'\d+))?).*?(?>\naddress\ width[ \t]*:\ (?'address_width'\d+))
    ## Separator Regex (?<=\n)\n
    cat /proc/cpuinfo | sed -e 's/flags[[:space:]]*:.* lm .*/address width\t: 64/;s/flags[[:space:]]*:.*/address width\t: 32/;/siblings[[:space:]]*:.*/d' >> $location
}

GetLinuxMemInfo() {
    ## Parser Regex (?sixn)(?>MemTotal:[ \t]*(?'mem_total_kb'\d+)\ kB).*?(?>MemFree:[ \t]*(?'mem_free_kb'\d+)\ kB).*?(?>Buffers:[ \t]*(?'buffers_kb'\d+)\ kB).*?(?>Cached:[ \t]*(?'cached_kb'\d+)\ kB).*?(?>SwapCached:[ \t]*(?'swap_cached_kb'\d+)\ kB).*?(?>Active:[ \t]*(?'active_kb'\d+)\ kB).*?(?>Inactive:[ \t]*(?'inactive_kb'\d+)\ kB).*?(?>SwapTotal:[ \t]*(?'swap_total_kb'\d+)\ kB).*?(?>SwapFree:[ \t]*(?'swap_free_kb'\d+)\ kB).*?(?>VmallocTotal:[ \t]*(?'vm_alloc_total_kb'\d+)\ kB).*?(?>VmallocUsed:[ \t]*(?'vm_alloc_used_kb'\d+)\ kB).*?(?>VmallocChunk:[ \t]*(?'vm_alloc_chunk_kb'\d+)\ kB) 
    cat /proc/meminfo >> $location
}

GetLinuxNetworkAdapters() {
    ## Separator regex (?<=Active:\S+)\n
    ## Parser regex (?sixn)^(?>(?'interface_name'[^\n]*)\n)(?>Link\ encap:(?'type'[^\n]*)\n)(?>HWaddr\ (?'mac_address'[^\n]*)\n)?(?>inet\ addr:\s*(?'ipv4_addr'\S+)(\s*Bcast:\s*(?'broadcast_addr'\S+))?\s+Mask:\s*(?'net_mask'\S+))?(?>inet6\ addr:\s*(?'ipv6_addr'\S+).*?)?(?>.*?MTU:\s*(?'mtu'\d+).*?\n)(?>RX\ packets:\s*(?'rx_packets'\d+)\s+errors:\s*(?'rx_errors'\d+).*?\n)(?>TX\ packets:\s*(?'tx_packets'\d+)\s+errors:\s*(?'tx_errors'\d+).*?\n).*?(?>RX\ bytes:\s*(?'rx_bytes'\d+)[^TX]+TX\ bytes:\s*(?'tx_bytes'\d+).*?\n).*?(?>Description:(?'description'[^\n]*)\n)(?>Active:(?'active'\S+))
    #important : do not remove bash global variable IFS=' '
    #loop through all reported interfaces.
    #TODO : remove Lo as this is present by default in all machines.
    for i in $(ip -o link show | awk -F': ' '{print $2}') 
    do
        #get link type from specified file path
        l_linktype="$(cat /sys/class/net/$i/type)"
        #check if the file "wireless" is present or not.
        if [ -d /sys/class/net/$i/wireless ] ; then
            l_linkencap="WireLess"
        elif [ $l_linktype -eq 1 ]; then
            l_linkencap="Ethernet"
        elif [ $l_linktype -eq 772 ]; then
            l_linkencap="Local Loopback"
        fi
        #echo the value
        echo "++++++++++++++++++++++++++++++++++++++++++" >> $location
        echo "Adapter Name: $i" >> $location
        echo "Link encap: $l_linkencap" >> $location
        #get the MAC address
        l_macaddress="$(cat /sys/class/net/$i/address)"
        #echo the value
        echo "HWaddr: $l_macaddress" >> $location
        #get the ipv4 address details
        #special logic for Local loopback adapter
        if [ $i == "lo" ]; then
            l_ipv4="$(ip addr show $i |grep -w inet | awk '{ print $2}'| cut -d "/" -f 1)"
            l_ipv4prefix="$(ip addr show $i |grep -w inet | awk '{ print $2}'| cut -d "/" -f 2)"
            #echo the value
            echo "inet addr: $l_ipv4 Mask: $l_ipv4prefix" >> $location
        else
            #the code for all interfaces other than "Lo"
            l_ipv4="$(ip addr show $i |grep -w inet | awk '{ print $2}'| cut -d "/" -f 1)"
            l_ipv4prefix="$(ip addr show $i |grep -w inet | awk '{ print $2}'| cut -d "/" -f 2)"
            l_ipv4bcast="$(ip addr show $i |grep -w inet | awk '{ print $4}')"
            l_ipv4assignmenttype="$(ip addr show $i | grep -w inet | awk '{ print $7}')"
            #echo the value
            echo "inet addr: $l_ipv4 Bcast: $l_ipv4bcast Mask: $l_ipv4prefix" >> $location
        fi
        #get the ipv6 address details for specified interface in variable
        $itemp="$(ip -6 addr show $i | grep -w inet6 )" 2>/dev/null
        for line in $temp
        do
            #get the IP address
            ipv6=$(echo "$line" | awk '{ print $2}' )
            #ipv6="$(grep -v ::1 <<< $line | awk '{ print $2}')"
            #get the IP scope
            ipv6scope=$(echo "$line" | awk '{ print $4}')
            #ipv6scope="$(grep -v ::1 <<< $line | awk '{ print $4}')"
            #echo op to screen
            echo "inet6 addr: $ipv6 # Scope: $ipv6scope" >> $location
        done
        #get MTU
        #MTU echo must end with a space, as the MAP XML pulls value from : to next space
        l_mtu="$(cat /sys/class/net/$i/mtu)"
        echo "MTU: $l_mtu " >> $location
        #get RX / TX packet details
        l_rxpackets="$(cat /sys/class/net/$i/statistics/rx_packets)"
        l_txpackets="$(cat /sys/class/net/$i/statistics/tx_packets)"
        l_rxerrors="$(cat /sys/class/net/$i/statistics/rx_errors)"
        l_txerrors="$(cat /sys/class/net/$i/statistics/tx_errors)"
        l_rxdropped="$(cat /sys/class/net/$i/statistics/rx_dropped)"
        l_txdropped="$(cat /sys/class/net/$i/statistics/tx_dropped)"
        #get RX / TX bytes details
        l_rxbytes="$(cat /sys/class/net/$i/statistics/rx_bytes)"
        l_txbytes="$(cat /sys/class/net/$i/statistics/tx_bytes)"
        echo "RX packets: $l_rxpackets errors: $l_rxerrors" >> $location
        echo "TX packets: $l_txpackets errors: $l_txerrors" >> $location
        echo "RX bytes: $l_rxbytes TX bytes: $l_txbytes" >> $location
        #get description
        l_description=""
        l_vendorFile="/sys/class/net/$i/device/vendor"
        l_deviceFile="/sys/class/net/$i/device/device"
        if [ -e "$l_vendorFile" -a -e "$l_deviceFile" ]; then
            l_vendor="$(cat $l_vendorFile)"
            l_device="$(cat $l_deviceFile)"
            l_description=$(lspci -d $l_vendor:$l_device | head -n 1 | awk -F ': ' '{print $2}')
            if [ -z "$l_description" ]; then
                l_description="$(lsusb -d $l_vendor:$l_device | head -n 1 | awk --posix -F '[[:alnum:]]{4}:[[:alnum:]]{4} ' '{print $2}')"
            fi
        fi
        echo "Description: $l_description" >> $location
        #get link state
        l_linkstate="$(cat /sys/class/net/$i/operstate)"
        if [ $l_linkstate = "up" ]; then
            echo "Active: true" >> $location
        else
            echo "Active: false" >> $location
        fi
    done
}

GetLinuxFileSystems() {
    #this script uses bash to get disk mount information from local Linux machine.
    #df utility must be installed , available on most installations except core linux.
    #split on new line only. Also IFS=$'\n' in bash/ksh93/zsh/mksh IFS=' ' 
    #disable globbing #no longer required. 
    #ser -o noglog #skips the tmpfs file system as these are RAM drives

    ## Separator Regex (?<=mode=[^\n]*)\n
    ## Parser Regex (?sxn)^(?>filesystem=(?'filesystem'[^\n]*)\n)(?>1kb_blocks=(?'onekb_blocks'[^\n]*)\n)(?>blocks_used=(?'blocks_used'[^\n]*)\n)(?>blocks_available=(?'blocks_available'[^\n]*)\n)(?>percent_used=(?'percent_used'[^\n]*)\n)(?>mount_point=(?'mount_point'[^\n]*)\n)(?>type=(?'type'[^\n]*)\n)(?>mode=(?'mode'[^\n]*))
    df -T -x tmpfs -x devtmpfs | awk 'NR>1 { print $1 " " $2 " " $3 " " $4 " " $5 " " $6 " " $7}' | {
        while read output 
        do
            l_filesystem=$(echo $output | awk '{ print $1 }')
            l_1kb_blocks=$(echo $output | awk '{ print $3 }')
            l_blocks_used=$(echo $output | awk '{ print $4 }')
            l_blocks_available=$(echo $output | awk '{ print $5 }')
            l_percent_used=$(echo $output | sed 's/\%//g' | awk '{ print $6 }')
            l_mount_point=$(echo $output | awk '{ print $7 }')
            l_type=$(echo $output | awk '{ print $2 }')
            #l_type=$(findmnt -rn $l_mount_point | awk '{ print $3 }' )
            l_mode=$(findmnt -rn $l_mount_point | awk '{ print $4 }' )
            #echo the values
            echo "++++++++++++++++++++++++++++++++++++++++++" >> $location
            echo "filesystem: $l_filesystem" >> $location
            echo "1kb_blocks: $l_1kb_blocks" >> $location
            echo "blocks_used: $l_blocks_used" >> $location
            echo "blocks_available: $l_blocks_available" >> $location
            echo "percent_used: $l_percent_used" >> $location
            echo "mount_point: $l_mount_point" >> $location
            echo "type: $l_type" >> $location
            echo "mode: $l_mode" >> $location
        done 
    }
}

GetLinuxSmBiosInfo() {
     ## Parser regex (?sixn)(?>\nBIOS\ Information\n)(?>\s*Vendor:\ *(?'bios_vendor'[^\n]*)\n)(?>\s*Version:\ *(?'bios_version'[^\n]*)\n)(?>\s*Release\ Date:\ *(?'bios_release_date'[^\n]*)\n).*?(?>\nSystem\ Information\n)(?>\s*Manufacturer:\ *(?'system_manufacturer'[^\n]*)\n)(?>\s*Product\ Name:\ *(?'system_product_name'[^\n]*)\n)(?>\s*Version:\ *(?'system_version'[^\n]*)\n)(?>\s*Serial\ Number:\ *(?'system_serial_number'[^\n]*)\n)(?>\s*UUID:\ *(?'system_uuid'[^\n]*)\n) 
     # First try identifying Xen
     # Detect Xen paravirtualized systems (which includes dom0 and domU PV).
     # If /proc/xen is detected, this means that the machine is either
     # Xen dom0 or Xen domU PV (paravirtualized). Detect which one it is.
     #Dom0 vs Xen DomU PV. Fully virtualized Xen VMs are detected below.
     virt_info=""
     if [ -e /proc/xen ]; then
        # /dev/xvc0 only exists on Xen domU PV systems. It does not exist on HVM DomU
        if [ -e /dev/xvc0 ]; then
            machine_type="Virtual"
            virt_info="Xen (domU PV)"
        else
            machine_type="Physical"
            virt_info="Xen (dom0)"
        fi
    fi
    # Try hal first as regular user, then dmicode as root
    # Return "Access Denied" if not running as root.
    # NOTE: Consider using lshw or parsing dmesg incase the
    # options below fail.
    if [ "$(which dmesg 2> /dev/null)" != "" ]; then
        #biosvendor=$(hal-get-property --udi /org/freedesktop/Hal/devices/computer --key system.firmware.vendor 2> /dev/null)
        #if [ $? -ne 0 ]; then# biosvendor=$(hal-get-property --udi /org/freedesktop/Hal/devices/computer --key smbios.bios.vendor)#fi
        #echo "Vendor: $biosvendor"
        version=`dmesg|grep -i 'DMI:'|sed 's/.*\(BIOS.*\)/\1/' | awk '{print $2}'`
        echo "BIOS Version: $version" >> $location
        biosdate=`dmesg|grep -i 'DMI:'|sed 's/.*\(BIOS.*\)/\1/' | awk '{print $3}'`
        echo "BIOS Release Date: $biosdate" >> $location
        hwvendor=`dmesg|grep -i 'DMI:'|sed 's/.*\(DMI.*\)/\1/' | awk '{print $2,$3}'`
        echo "BIOS Manufacturer: $hwvendor" >> $location
        # If we got a Xen (dom0) VM, we will append this information to the end of the 'Product Name'
        # If we got a Xen (domU PV) VM, we append that as well, but it will be the only string since there is no hal entry
        prodname=`dmesg|grep -i 'DMI:'|sed 's/.*\(Virtual.*\)/\1/' | awk '{print $1,$2}'|awk -F"/" '{print $1}'|awk -F"," '{print $1}'`
        if [ -n "$virt_info" ]; then
            echo "Product Name: $prodname $virt_info" >> $location
        else
            echo "Product Name: $prodname" >> $location
        fi
        echo "Hardware Version: $hwver" >> $location
        echo "Hardware Serial Number: $hwserial" >> $location
        echo "Hardware UUID: $hwid" >> $location
    elif [ `id -u` != "0" ]; then
        echo __MAP_INVENTORY_ACCESS_DENIED__ 1>&2
    else
        dmidecode -t 0,1
    fi
}

GetLinuxPCIDevices() {
    lspci -D >> $location
}

GetLinuxRpmPackages() {
    if [ "$(which rpm 2> /dev/null)" != "" ]; then
        #check if yum is installed
        if [ -x "$(command -v yum)" ]; then
            yum list installed >> $location
            echo "NAME,VERSION,RELEASE,GROUP,VENDOR,SUMMARY" > $packagecsv
            rpm -qa --queryformat "%{NAME},%{VERSION},%{RELEASE},%{VENDOR},%{SUMMARY}\n" | sort -t\; -k 1 >> $packagecsv
        else
            rpm -qa >> $location
            echo "NAME,VERSION,RELEASE,VENDOR,SUMMARY" > $packagecsv
            rpm -qa --queryformat "%{NAME},%{VERSION},%{RELEASE},%{VENDOR},%{SUMMARY}\n" | sort -t\; -k 1 >> $packagecsv
        fi
    fi
}

GetLinuxDpkgPackages() {
    if [ "$(which dpkg 2> /dev/null)" != "" ]; then
        dpkg -l >> $location
        echo "Name,Version,Section,Homepage,Source,Architecture" > $packagecsv
        dpkg-query -Wf '${Package},${Version},${Section},${Homepage},${Source},${Architecture}\n' | sort >> $packagecsv
    fi
}

GetLinuxOracleInstall() {
     if [ -e /etc/oratab ]; then
     echo "Database Installed: Oracle" >> $location
        for oraInstall in `cat /etc/oratab|egrep ':N|:Y'|grep -v \*`
        do
            oraSid=`echo $oraInstall | cut -f1 -d':'`
            oraHome=`echo $oraInstall | cut -f2 -d':'`
            if [ `id -u` != "0" ]; then
                oraVersion=`echo $oraHome | cut -d/ -f6`
            else
                oraVersion=`strings $oraHome/bin/oracle | grep NLSRTL`                
            fi
            echo "++++++++++++++++++++++++++++++++++++++++++" >> $location
            echo "Oracle Database Name: $oraSid" >> $location
            echo "Oracle Home Directory: $oraHome" >> $location
            echo "Oracle Version: $oraVersion" >> $location
        done
    fi
}

GetLinuxMySQLInstall() {
    echo "Database Installed: MySQL" >> $location
    echo "Enter MySQL admin Username"
    read -p "MySQL UserName: " mysqluser
    echo "Enter MySQL admin Password"
    read -s -p "MySQL Password: " mysqlpass
    ## TODO Need to fix MySQL prompt filter not working
    if [ [$mysqluser == *"echo"*] ]; then
        echo "Unable to connect MySQL instance with empty credentials" >> $location
    else
        mysql -u $mysqluser -p$mysqlpass -e "show databases;" | grep -v Database | grep -v schema >> $location
    fi
}

GetLinuxWebInstall() {
    if [ -x "$(command -v apachectl)" ]; then
        echo "Web Application Installed: Apache" >> $location
        apachectl -S >> $location
    elif [ -x "$(command -v apache2ctl)" ]; then
        echo "Web Application Installed: Apache" >> $location
        apache2ctl -S >> $location
    else        
        echo "Web Application Installed: httpd" >> $location
        httpd -S >> $location
    fi
}

#Main Script Block
echo "================================================================" > $location
echo -e "System Name: \t` hostname`" >> $location
echo -e "System Domain Name: \t`dnsdomainname`" >> $location
echo -e "Generated on: \t\t`date`" >> $location
echo -e "Running as: \t\t\t`whoami`" >> $location
echo "================================================================" >> $location
echo "Output of Server: $hostname" >> $location
echo "================================================================" >> $location
echo "1> BIOS and System Information " >> $location
GetLinuxDistribution;
echo "================================================================" >> $location
echo "2> Processor Information " >> $location
GetLinuxProcessors;
echo "================================================================" >> $location
echo "3> Memory Information " >> $location
GetLinuxMemInfo;
echo "================================================================" >> $location
echo "4> Network Information " >> $location
GetLinuxNetworkAdapters;
echo "================================================================" >> $location
echo "5> File System Information " >> $location
GetLinuxFileSystems;
echo "================================================================" >> $location
echo "6> BIOS Information " >> $location
GetLinuxSmBiosInfo;
echo "================================================================" >> $location
echo "7> PCI Devices Information " >> $location
GetLinuxPCIDevices;
echo "================================================================" >> $location
echo "8> Packages Installed " >> $location
if [ $iscentos -eq 0 ]; then
    GetLinuxRpmPackages;
elif [ $isubuntu -eq 0 ]; then
    GetLinuxDpkgPackages;
else
    echo "Packages: Host Not supported"
fi
echo "================================================================" >> $location
echo "9> Databases Configured " >> $location
check_db;
if [ $isoracle -eq 0 ]; then
    GetLinuxOracleInstall;
elif [ -x "$(command -v mysql)" ]; then
    GetLinuxMySQLInstall;
else
    echo "Database Installed: NA" >> $location
fi
echo "================================================================" >> $location
echo "10> Web App Configured " >> $location
check_web;
if [ $isweb -eq 0 ]; then
    GetLinuxWebInstall;
else
    echo "Web Application Installed: NA" >> $location
fi