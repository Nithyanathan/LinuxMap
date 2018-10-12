#!/bin/bash

GetLinuxDistribution() {
## Parser Regex (?sxn)^(?>Distributor\ ID:\t(?'distributorId'[^\n]*)\n)(?>Description:\t(?'description'[^\n]*)\n)(?>Release:\t(?'release'[^\n]*)\n)(?>Codename:\t(?'codename'[^\n]*)\n)
    if [ -e /etc/redhat-release ];then
        l_distributor=`cat /etc/redhat-release |sed s/\ release.*//`
        l_release=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
        c_codename=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
        l_description=$l_distributor' '$l_release' '$c_codename
        echo "Distributor ID: $l_distributor"
        echo "Description: $l_description"
        echo "Release: $l_release"
        echo "Codename: $c_codename"
    elif [ -e /etc/os-release ];then
        l_description=`cat /etc/os-release | sed -n -e 's/^PRETTY_NAME=\(.*\)/\1/p'`
        l_release=`cat /etc/os-release | sed -n -e 's/^VERSION_ID="\(.*\)"/\1/p'`
        echo "Distributor ID: $l_description"
        echo "Description: $l_description"
        echo "Release: $l_release"
        echo "Codename: $c_codename"
    else
        echo "Distributor ID: UNKNOWN"echo "Description: UNKNOWN"echo "Release: UNKNOWN"echo "Codename: UNKNOWN"
    fi
}

GetLinuxProcessors() {
    ## Parser Regex (?sixn)^(?>processor[ \t]*:\ (?'processor'\d+)).*?(?>\nvendor_id[ \t]*:\ (?'vendor_id'[^\n]+)).*?(?>\ncpu\ family[ \t]*:\ (?'cpu_family'\d+)).*?(?>\nmodel[ \t]*:\ (?'model'\d+)).*?(?>\nmodel\ name[ \t]*:\ (?'model_name'[^\n]+)).*?(?>\nstepping[ \t]*:\ (?'stepping'\d+)).*?(?>\ncpu\ MHz[ \t]*:\ (?'cpu_mhz'\d+)).*?(?>\ncache\ size[ \t]*:\ (?'cache_size_kb'\d+)\ KB).*?(?>(\nphysical\ id[ \t]*:\ (?'physical_id'\d+))?).*?(?>(\ncore\ id[ \t]*:\ (?'core_id'\d+))?).*?(?>\naddress\ width[ \t]*:\ (?'address_width'\d+))
    ## Separator Regex (?<=\n)\n
    cat /proc/cpuinfo | sed -e 's/flags[[:space:]]*:.* lm .*/address width\t: 64/;s/flags[[:space:]]*:.*/address width\t: 32/;/siblings[[:space:]]*:.*/d'
}

GetLinuxMemInfo() {
    ## Parser Regex (?sixn)(?>MemTotal:[ \t]*(?'mem_total_kb'\d+)\ kB).*?(?>MemFree:[ \t]*(?'mem_free_kb'\d+)\ kB).*?(?>Buffers:[ \t]*(?'buffers_kb'\d+)\ kB).*?(?>Cached:[ \t]*(?'cached_kb'\d+)\ kB).*?(?>SwapCached:[ \t]*(?'swap_cached_kb'\d+)\ kB).*?(?>Active:[ \t]*(?'active_kb'\d+)\ kB).*?(?>Inactive:[ \t]*(?'inactive_kb'\d+)\ kB).*?(?>SwapTotal:[ \t]*(?'swap_total_kb'\d+)\ kB).*?(?>SwapFree:[ \t]*(?'swap_free_kb'\d+)\ kB).*?(?>VmallocTotal:[ \t]*(?'vm_alloc_total_kb'\d+)\ kB).*?(?>VmallocUsed:[ \t]*(?'vm_alloc_used_kb'\d+)\ kB).*?(?>VmallocChunk:[ \t]*(?'vm_alloc_chunk_kb'\d+)\ kB) 
    cat /proc/meminfo
}

GetLinuxNetworkAdapters() {
    ## Separator regex (?<=Active:\S+)\n
    ## Parser regex (?sixn)^(?>(?'interface_name'[^\n]*)\n)(?>Link\ encap:(?'type'[^\n]*)\n)(?>HWaddr\ (?'mac_address'[^\n]*)\n)?(?>inet\ addr:\s*(?'ipv4_addr'\S+)(\s*Bcast:\s*(?'broadcast_addr'\S+))?\s+Mask:\s*(?'net_mask'\S+))?(?>inet6\ addr:\s*(?'ipv6_addr'\S+).*?)?(?>.*?MTU:\s*(?'mtu'\d+).*?\n)(?>RX\ packets:\s*(?'rx_packets'\d+)\s+errors:\s*(?'rx_errors'\d+).*?\n)(?>TX\ packets:\s*(?'tx_packets'\d+)\s+errors:\s*(?'tx_errors'\d+).*?\n).*?(?>RX\ bytes:\s*(?'rx_bytes'\d+)[^TX]+TX\ bytes:\s*(?'tx_bytes'\d+).*?\n).*?(?>Description:(?'description'[^\n]*)\n)(?>Active:(?'active'\S+))
    #important : do not remove bash global variable IFS=' '
    #loop through all reported interfaces.
    #TODO : remove Lo as this is present by default in all machines.
    for i in $(ip -o link show | awk -F': ' '{print $2}') 
    do
        #echo the interface name
        echo $i
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
        echo "Link encap:$l_linkencap"
        #get the MAC address
        l_macaddress="$(cat /sys/class/net/$i/address)"
        #echo the value
        echo "HWaddr $l_macaddress"
        #get the ipv4 address details
        #special logic for Local loopback adapter
        if [ $i == "lo" ]; then
            l_ipv4="$(ip addr show $i |grep -w inet | awk '{ print $2}'| cut -d "/" -f 1)"
            l_ipv4prefix="$(ip addr show $i |grep -w inet | awk '{ print $2}'| cut -d "/" -f 2)"
            #echo the value
            echo "inet addr:$l_ipv4 Mask:$l_ipv4prefix"
        else
            #the code for all interfaces other than "Lo"
            l_ipv4="$(ip addr show $i |grep -w inet | awk '{ print $2}'| cut -d "/" -f 1)"
            l_ipv4prefix="$(ip addr show $i |grep -w inet | awk '{ print $2}'| cut -d "/" -f 2)"
            l_ipv4bcast="$(ip addr show $i |grep -w inet | awk '{ print $4}')"
            l_ipv4assignmenttype="$(ip addr show $i | grep -w inet | awk '{ print $7}')"
            #echo the value
            echo "inet addr:$l_ipv4 Bcast:$l_ipv4bcast Mask:$l_ipv4prefix"
        fi
        #get the ipv6 address details for specified interface in variable
        $itemp="$(ip -6 addr show $i | grep -w inet6 )"
        for line in $temp ;do
            #get the IP address
            ipv6=$(echo "$line" | awk '{ print $2}' )
            #ipv6="$(grep -v ::1 <<< $line | awk '{ print $2}')"
            #get the IP scope
            ipv6scope=$(echo "$line" | awk '{ print $4}')
            #ipv6scope="$(grep -v ::1 <<< $line | awk '{ print $4}')"
            #echo op to screen
            echo "inet6 addr: $ipv6 # Scope:$ipv6scope"
        done
        #get MTU
        #MTU echo must end with a space, as the MAP XML pulls value from : to next space
        l_mtu="$(cat /sys/class/net/$i/mtu)"
        echo "MTU:$l_mtu "
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
        echo "RX packets:$l_rxpackets errors:$l_rxerrors"
        echo "TX packets:$l_txpackets errors:$l_txerrors"
        echo "RX bytes:$l_rxbytes TX bytes:$l_txbytes"
        #get description
        l_description=""l_vendorFile="/sys/class/net/$i/device/vendor"
        l_deviceFile="/sys/class/net/$i/device/device"
        if [ -e "$l_vendorFile" -a -e "$l_deviceFile" ]; then
            l_vendor="$(cat $l_vendorFile)"
            l_device="$(cat $l_deviceFile)"
            l_description=$(lspci -d $l_vendor:$l_device | head -n 1 | awk -F ': ' '{print $2}')
            if [ -z "$l_description" ]; then
                l_description="$(lsusb -d $l_vendor:$l_device | head -n 1 | awk --posix -F '[[:alnum:]]{4}:[[:alnum:]]{4} ' '{print $2}')"
            fi
        fi
        echo "Description:$l_description"
        #get link state
        l_linkstate="$(cat /sys/class/net/$i/operstate)"
        if [ $l_linkstate = "up" ]; then
            echo "Active:true"
        else
            echo "Active:false"
        fi
    done
}

GetLinuxFileSystems() {
    #this script uses bash to get disk mount information from local Linux machine.
    #df utility must be installed , available on most installations except core linux.
    #split on new line only. Also IFS=$'\n' in bash/ksh93/zsh/mksh IFS=' ' 
    #disable globbing #no longer required. 
    #ser -o noglog #skips the tmpfs file system as these are RAM drives
    df -T -x tmpfs -x devtmpfs | awk 'NR>1 { print $1 " " $2 " " $3 " " $4 " " $5 " " $6 " " $7}' | {
        while read output do
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
            echo "filesystem=$l_filesystem"
            echo "1kb_blocks=$l_1kb_blocks"
            echo "blocks_used=$l_blocks_used"
            echo "blocks_available=$l_blocks_available"
            echo "percent_used=$l_percent_used"
            echo "mount_point=$l_mount_point"
            echo "type=$l_type"
            echo "mode=$l_mode"
        done 
    }
}

GetLinuxSmBiosInfo() {}

GetLinuxPCIDevices() {}

GetLinuxCdromDrives() {}

GetLinuxRpmPackages() {}

GetLinuxDpkgPackages() {}

GetLinuxOracleInstall() {}

GetLinuxMySqlInstall() {}

GetLinuxWebAppInstall() {}