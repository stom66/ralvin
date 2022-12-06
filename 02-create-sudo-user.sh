#!/bin/bash

# Create a sudo user
# Expects $1 to be a username
# Expects $2 to be a password

if [ ! -z "$1" && ! -z "$2"]; then
	useradd $1
	echo "$2" | passwd "$1" --stdin

	usermod -aG wheel $1

	# Optional: disable password entry for sudo use:
	#echo "${1} ALL=(ALL) NOPASSWD: ALL" | sudo tee --append /etc/sudoers

	echo "RALVIN | create-sudo-user | Created user ${1}" >> ./RALVIN.log
else
	echo "RALVIN | create-sudo-user | Error creating user, missing username or password" >> ./RALVIN.log
fi