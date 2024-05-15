#!/bin/bash

echo "This uninstaller script requires root privileges."
echo "Checking..."
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit 0
else
    echo "Uninstallation continues"
fi

# Stop the Nexus Repository Manager service if it exists
if systemctl is-active --quiet nexus-repository-manager.service; then
    systemctl stop nexus-repository-manager.service
fi

# Disable the Nexus Repository Manager service if it exists
if systemctl is-enabled --quiet nexus-repository-manager.service; then
    systemctl disable nexus-repository-manager.service
fi

# Manually remove the problematic pre-removal script of nexus-repository-manager
if [ -e /var/lib/dpkg/info/nexus-repository-manager.prerm ]; then
    mv /var/lib/dpkg/info/nexus-repository-manager.prerm /var/lib/dpkg/info/nexus-repository-manager.prerm.bak
fi

# Force remove Nexus Repository Manager package
dpkg --remove --force-remove-reinstreq nexus-repository-manager

# Remove Nexus directories
rm -rf /opt/sonatype
rm -f /etc/systemd/system/nexus-repository-manager.service
rm -f /etc/apt/sources.list.d/sonatype-community.list
rm -rf /var/cache/apt/archives/nexus-repository-manager_*.deb
rm -rf /usr/share/doc/nexus-repository-manager

# Remove BellSoft Java package if installed
if dpkg -l | grep -q bellsoft-java8; then
    dpkg --purge bellsoft-java8 || true
fi

# Remove Temurin JDK 8 package if installed
if dpkg -l | grep -q temurin-8-jdk; then
    apt remove --purge temurin-8-jdk -y || true
fi

# Remove residual configuration files
dpkg --purge ca-certificates-java java-common

# Clean up unused dependencies
apt autoremove -y

# Clean up any remaining configuration files
apt clean

echo "Uninstallation completed."

# Optionally remove user and group created for Nexus
if id -u nexus3 >/dev/null 2>&1; then
    userdel nexus3
fi

if getent group nexus3 >/dev/null 2>&1; then
    groupdel nexus3
fi

# Remove any remaining configuration files
dpkg --purge nexus-repository-manager ca-certificates-java java-common

# Verify the removal
echo "Verifying the removal of Nexus and Java packages..."
dpkg -l | grep nexus
dpkg -l | grep java
