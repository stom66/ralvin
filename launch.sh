#!/bin/bash

# This script is designed to be copy-pasted over SSH and give you a simple way to 
# clone the various scripts and trigger the installer


sudo dnf install -y -q git
git clone https://github.com/stom66/ralvin/ ralvin && cd ralvin
chmod +x ralvin.sh
sudo ./ralvin.sh \
	--fqdn-hostname "example.domain.tld" \
	--ssh-custom-port 22 \
	--sudo-user-name "rocky" \
	--sudo-user-password "password1" \
	--sudo-user-pubkey "sshpublickeykey" \
	--virtualmin-user "root" \
	--virtualmin-password "password2" \
	--mysql-root-password "password3" \
	--aws-access-key "EXAMPLEACCESSKEY" \
	--aws-secret-key "EXAMPLESECRETKEY"