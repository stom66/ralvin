#!/bin/bash

# Apply Network and hostname settings
# Expects $1 to be an FQDN
declare PREFIX="RALVIN | hostname-setup |"

# Set correct hostname
hostnamectl set-hostname --static "$1"

# Add self to DNS lookup servers (needed for virtualmin)
echo "prepend domain-name-servers 127.0.0.1;" | sudo tee -a /etc/dhcp/dhclient.conf

# Check for AWS cloud config file
$CLOUD_CFG_FILE = "/etc/cloud/cloud.cfg"
if test -f "$CLOUD_CFG_FILE"; then
	echo "preserve_hostname: true" | sudo tee -a $CLOUD_CFG_FILE
fi

# Retart the network
systemctl restart NetworkManager

echo "${PREFIX} Configured system to use hostname: ${1}" >> ./RALVIN.log