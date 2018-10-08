# LinuxMap
get-info.sh bash script allows to get hardware & software inventory for linux servers

Current capabilities
    1. Get OS information
    2. Get package information in txt and csv
    3. Get system info using hwinfo
    4. NFS and CIFS Share information
    5. Cluster Information
    6. Oracle database Information with database names and directory
    7. Web Server Information
    8. MySQL database detection along with database names

URGENT REQUIREMENT:
    1. Run script without prompting for password for sudo or mysql. This will allow us to execute the script without password prompt on multiple servers. Password prompt can be removed from sudoers file but will customer agree to take that action on server inventory?

Other capabilties required
    1. Additional cluster scan apart from pcs
    2. Parsing the data - making it catalog ready

Fixes Required:
    1. check_web function - returning isweb 1 even though no port 80/443 configured - Tested for Ubuntu
    2. check_cluster - returning iscluster 127 even though pcs command not found - Tested for Ubuntu / CentOS / RedHat
    3. Find way to collect Mysql database inventory. Requires password prompt.
