#!/bin/bash

# This script is designed to be copy-pasted over SSH and give you a simple way to 
# clone the various scripts and trigger the installer


sudo dnf install -y -q git
git clone https://github.com/stom66/ralvin/ ralvin && cd ralvin
chmod +x ralvin.sh
sudo ./ralvin.sh \
	--domain "example.domain.com" \
	--ssh-port 2022 \
	--sudo-user-name "rocky" \
	--sudo-user-password "yourPassword1" \
	--sudo-user-pubkey "ssh-ed25520 yourkeygoeshere" \
	--virtualmin-user root \
	--virtualmin-password "yourPassword1" \
	--mysql-password "yourPassword3" \
	--aws-access-key "EXAMPLEACCESSKEY" \
	--aws-secret-key "EXAMPLESECRETKEY"