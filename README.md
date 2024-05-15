# nexus
Bash script to install nexus correctly in Debian 11 and 12.

Script requires that the user is in sudoers.

Make the Script Executable:

```bash
chmod +x setup_nexus.sh
```

Run the Script with Superuser Privileges:

```bash
sudo ./setup_nexus.sh
```

You can replace bellsoft Java line with the below:

```bash
apt install openjdk-8-jdk -y
```