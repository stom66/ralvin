#!/bin/bash

# Add public key to user rocky authorized_keys
# Expects $1 to be a username
# Expects $2 to be a valid public key

if [ ! -z "$1" && ! -z "$2" ]; then
	$PATH = "/home/$1/.ssh"

	mkdir ${PATH}
	chmod 700 ${PATH}
	touch "${PATH}/authorized_keys"
	chmod 600 "${PATH}/authorized_keys"
	echo "${2}" sudo tee --append "${PATH}/authorized_keys"
	chown -R ${1}:${1} ${PATH}

	echo "RALVIN | add-public-key | Added pubkey to ${PATH}/authorized_keys: ${PUBKEY}" >> ./RALVIN.log
else
	echo "RALVIN | add-public-key | Error adding public key to authorized_keys, missing username or public_key" >> ./RALVIN.log
fi