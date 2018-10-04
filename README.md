# LinuxMap
get-info.sh bash script allows to get hardware & software inventory for linux servers

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

Current capabilities
    1. Get OS information
    2. Get package information in txt and csv
    3. Get system info using hwinfo

Added capabilities
    1. NFS and CIFS Share information
    2. Cluster Information
    3. Oracle database Information
    4. Web Server Information

Other capabilties required
    1. Additional cluster scan apart from pcs
    2. Scan for mysql and other databases
    3. Parsing the data - making it catalog ready