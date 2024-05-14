#!/bin/bash

##########################################################################################################
# Author: Sysadmin                                                                                       #
# mail: admin@sysadmin.info.pl                                                                           #
# Use freely                                                                                             #
# Key Points:                                                                                            #
# 1. **Root Privileges Check**: The script verifies if it's being run as root.                           #
# 2. **Package Installation**: It installs necessary packages, including `gnupg` and `curl`.             #
# 3. **Nexus Repository Installation**: Downloads and installs Nexus Repository Manager.                 #
# 4. **Java Installation**: Downloads and installs the specified Java version.                           #
# 5. **Permissions**: Sets the correct ownership and permissions for Nexus directories.                  #
# 6. **Service Management**: Stops and starts the Nexus service at appropriate points.                   #
# 7. **OrientDB Console Commands**: Connects to the OrientDB console to update the admin password.       #
# 8. **Validation**: Uses `curl` to check if the Nexus service is running and accessible.                #
# This script covers the installation and setup process comprehensively,                                 #
# including handling dependencies and setting up the necessary environment for Nexus Repository Manager. #
##########################################################################################################

echo "This quick installer script requires root privileges."
echo "Checking..."
if [[ $(/usr/bin/id -u) -ne 0 ]];
then
    echo "Not running as root"
    exit 0
else
    echo "Installation continues"
fi

SUDO=
if [ "$UID" != "0" ]; then
    if [ -e /usr/bin/sudo -o -e /bin/sudo ]; then
        SUDO=sudo
    else
        echo "*** This quick installer script requires root privileges."
        exit 0
    fi
fi

# Install necessary packages
apt install gnupg gnupg1 gnupg2 -y
wget -P /etc/apt/sources.list.d/ https://repo.sonatype.com/repository/community-hosted/deb/sonatype-community.list
sed -i '1i deb [arch=all trusted=yes] https://repo.sonatype.com/repository/community-apt-hosted/ bionic main' /etc/apt/sources.list.d/sonatype-community.list
sed -i '2s/^/#/' /etc/apt/sources.list.d/sonatype-community.list
wget -q -O - https://repo.sonatype.com/repository/community-hosted/pki/deb-gpg/DEB-GPG-KEY-Sonatype.asc | apt-key add -
apt update && apt install nexus-repository-manager -y

# Stop the Nexus Repository Manager service
systemctl stop nexus-repository-manager.service

# Install Java JDK 8 update 412
wget https://download.bell-sw.com/java/8u412+9/bellsoft-jdk8u412+9-linux-amd64.deb
dpkg -i bellsoft-jdk8u412+9-linux-amd64.deb
apt --fix-broken install -y
dpkg -i bellsoft-jdk8u412+9-linux-amd64.deb

# Set correct ownership and permissions
chown -R nexus3:nexus3 /opt/sonatype
chmod -R 750 /opt/sonatype

# Start the Nexus Repository Manager service
systemctl start nexus-repository-manager.service

# Install curl
apt install curl -y

# Extract the first IP address from `hostname -I` and store it in a variable
IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo "sleep 120 seconds ..."
sleep 120

# Use the IP address variable
echo "The IP address is: $IP_ADDRESS"
curl http://$IP_ADDRESS:8081

# Stop the Nexus Repository Manager service
systemctl stop nexus-repository-manager.service

# Execute OrientDB console commands using a here document
java -jar /opt/sonatype/nexus3/lib/support/nexus-orient-console.jar <<EOF
connect plocal:/opt/sonatype/sonatype-work/nexus3/db/security admin admin
select * from user where id = "admin"
update user SET password="\$shiro1\$SHA-512\$1024\$NE+wqQq/TmjZMvfI7ENh/g==\$V4yPw8T64UQ6GfJfxYq2hLsVrBY8D1v+bktfOxGdt4b/9BthpWPNUy/CBk6V9iA0nHpzYzJFWO8v/tZFtES8CA==" UPSERT WHERE id="admin"
exit
EOF

# Set correct ownership and permissions
chown -R nexus3:nexus3 /opt/sonatype
chmod -R 750 /opt/sonatype

# Start the Nexus Repository Manager service
systemctl start nexus-repository-manager.service

# Check logs with the below command:
# sudo tail -f /opt/sonatype/sonatype-work/nexus3/log/nexus.log
