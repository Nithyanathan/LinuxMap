# LinuxMap
get-info.sh bash script allows to get hardware & software inventory for linux servers

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

Fixes Required:
    1. check_web function - returning isweb 1 even though no port 80/443 configured - Tested for Ubuntu
    2. check_cluster - returning iscluster 127 even though pcs command not found - Tested for Ubuntu / CentOS / RedHat
    3. Find way to collect Mysql database inventory.