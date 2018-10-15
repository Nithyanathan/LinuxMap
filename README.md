# LinuxMap
get-info.sh bash script allows to get hardware & software inventory for linux servers

Current capabilities
    1. Get OS information
    2. Get package information in txt and csv
    3. Get system info using hwinfo
    4. NFS and CIFS Share information
    5. Cluster Information (requires sudo)
    6. Oracle database Information with database names and directory
    7. Web Server Information (httpd if running locally, apache works ok)
    8. MySQL database detection along with database names (When running locally)
    9. IP Address information

Other capabilties required
    1. Additional cluster scan apart from pcs - Coro
    2. Parsing the data - making it catalog ready
    3. Load Balancing data
    4. Databases - Postgress, SQLite, MariaDB, SQL Server
    5. Web Application - Tomcat

Fixes Required:
    1. check_web function - returning isweb 1 even though no port 80/443 configured - Tested for Ubuntu
    2. MySQL username / password prompt when running on multiple computers.
    3. httpd command not returning output when running remotely.
    4. Network configuration not collected for remote CentOS, works for Ubuntu. Most likely due to bash.rc profile
    5. PCI device configuration not collected for remote CentOS, works for Ubuntu. Most likely due to bash profile
