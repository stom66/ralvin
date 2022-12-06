#!/bin/bash

# Check we have root perms
if [[ "${UID}" -ne 0 ]]; then
    echo " You need to run this script as root"
    exit 1
fi

# Setup vars
declare -l DOMAIN
declare PUBKEY
declare SUDO_USER
declare SUDO_PASSWORD
declare VMIN_USER
declare VMIN_PASSWORD
declare MYSQL_PASSWORD
declare WEBMIN_PASSWORD
declare AWS_ACCESS_KEY
declare AWS_SECRET_KEY

# Parse provided parameters
while [ $# -gt 0 ]; do
	key="$1"
	case $key in
		-h|--help)
			echo "Rocky Amazon LightSail Virtualmin Installer (RALVIN)"
			echo " "
			echo "More information is available at https://github.com/stom66/ralvin"
			echo " "
			echo "Options:"
			echo "  -h, --help                                show brief help"
			echo "  -d, --domain [domain.tld]                 specify an FQDN to use as the system hostname"
			echo "  -k, --pubkey [valid pubkey]               specify an public key to be added to the authorized_keys file"
			echo "  -su, --sudo-user [root]                   specify a username to add a sudo account to"
			echo "  -sp, --sudo-password [mypassword]         specify a password for the sudo account"
			echo "  -vu, --virtualmin-user [root]             specify a user to enable the Vitualmin admin panel password for"
			echo "  -vp, --virtualmin-password [mypassword]   specify a password to use for the Virtualmin admin panel"
			echo "  -mp, --mysql-password [mypassword]        specify a password to use for the MySQL root user"
			echo "  -wp, --webmin-password [mypassword]       specify a password to use for the default domain user"
			echo "  -a, --aws-access-key [key]                optional: aws access key to use for aws-cli"
			echo "  -s, --aws-secret-key [key]                optional: aws secret key to use for aws-cli"
			echo "  -ss, --ssh-port [number]                  optional: a custom port to use for the ssh server"
			exit 0
			;;
		-d|--domain)
			DOMAIN="$2"
			shift
			shift
			;;
		-k|--pubkey)
			PUBKEY="$2"
			shift
			shift
			;;
		-vu|--virtualmin-user)
			VMIN_USER="$2"
			shift
			shift
			;;
		-vp|--virtualmin-password)
			VMIN_PASSWORD="$2"
			shift
			shift
			;;
		-su|--sudo-user)
			SUDO_USER="$2"
			shift
			shift
			;;
		-sp|--sudo-password)
			SUDO_PASSWORD="$2"
			shift
			shift
			;;
		-mp|--mysql-password)
			MYSQL_PASSWORD="$2"
			shift
			shift
			;;
		-wp|--webmin-password)
			WEBMIN_PASSWORD="$2"
			shift
			shift
			;;
		-a|--aws-access-key)
			AWS_ACCESS_KEY="$2"
			shift
			shift
			;;
		-s|--aws-secret-key)
			AWS_SECRET_KEY="$2"
			shift
			shift
			;;
		-ss|--ssh-port)
			SSH_PORT="$2"
			shift
			shift
			;;
		*)
			break
			;;
	esac
done


printf "\n|| Starting RALVIN. Checking config \n"
printf "|| ================================ \n"

# Check we have a domain to use for configuration, prompt if not
if [ -z "$DOMAIN" ]; then
	read -e -p "|| Enter a valid FQDN: " -i "example.com" DOMAIN
fi

# Quit out if the user failed to provide a FQDN
if [ -z "$DOMAIN" ]; then
	printf "|| You must specify a FQDN. Script is exiting.\n\n"
	exit 0
fi

# Check if we're using a pubkey, or request one
if [ -z "$PUBKEY" ]; then
	read -e -p "|| Enter an optional public key to install: " -i "${PUBKEY}" PUBKEY
fi

# Check we have a sudo user account name to create
if [ -z "$SUDO_USER" ]; then
	read -e -p "|| Enter a name for the sudo user account: " -i "rocky" SUDO_USER
fi

# Check we have a password to use for the Virtualmin admin
if [ -z "$SUDO_PASSWORD" ]; then
	SUDO_PASSWORD=$(date +%s|sha256sum|base64|head -c 32)
	read -e -p "|| Enter a password for the Virtualmin admin panel: " -i "${SUDO_PASSWORD}" SUDO_PASSWORD
fi

# Check we have a user to set the password for
if [ -z "$VMIN_USER" ]; then
	read -e -p "|| Enter a valid user to grant access to the Virtualmin admin panel: " -i "root" VMIN_USER
fi

# Check we have a password to use for the Virtualmin admin
if [ -z "$VMIN_PASSWORD" ]; then
	VMIN_PASSWORD=$(date +%s|sha256sum|base64|head -c 32)
	read -e -p "|| Enter a password for the Virtualmin admin panel: " -i "${VMIN_PASSWORD}" VMIN_PASSWORD
fi

# Check we have a password to use for the default domain webmin admin
if [ -z "$WEBMIN_PASSWORD" ]; then
	WEBMIN_PASSWORD=$(date +%s|sha256sum|sha256sum|base64|head -c 32)
	read -e -p "|| Enter a password for the default domain Webmin user: " -i "${WEBMIN_PASSWORD}" WEBMIN_PASSWORD
fi

# Check we have a password to set for the MySQL root user
if [ -z "$MYSQL_PASSWORD" ]; then
	MYSQL_PASSWORD=$(date +%s|sha256sum|sha256sum|base64|head -c 32)
	read -e -p "|| Enter a password for the MySQL root user: " -i "${MYSQL_PASSWORD}" MYSQL_PASSWORD
fi

# AWS Credentials
# Check for an AWS access key
if [ -z "$AWS_ACCESS_KEY" ]; then
	read -e -p "|| Enter an (optional) aws-cli ACCESS KEY: " -i "${AWS_ACCESS_KEY}" AWS_ACCESS_KEY
fi

# Check for an AWS secret key
if [ -z "$AWS_SECRET_KEY" ]; then
	read -e -p "|| Enter an (optional) aws-cli SECRET KEY: " -i "${AWS_SECRET_KEY}" AWS_SECRET_KEY
fi

# Check for a a custom SSH port
if [ -z "$SSH_PORT" ]; then
	read -e -p "|| Enter an (optional) custom SSH port: " -i "${SSH_PORT}" SSH_PORT
fi

#
# Start script main
#


# Add the sudo user
sudo sh 02-create-sudo-user.sh "${SUDO_USER}" "${SUDO_PASSWORD}"

# Add pubkey
if [ -z "$PUBKEY" ]; then
	echo "RALVIN | add-public-key | Skipping pubkey (none provided)" >> ./RALVIN.log
else
	sudo sh 05-add-public-key.sh -k "${SUDO_USER}" "${PUBKEY}"
fi

# Configure hostname and network
sudo sh 06-harden-ssh.sh "${SSH_PORT}"

# Configure hostname and network
sudo sh 10-hostname-setup.sh "${DOMAIN}"

# Trigger yum updates and dependecy installs
sudo sh 15-dnf-update-and-install-dependencies.sh

# Add aws-cli

if [ -z "$AWS_ACCESS_KEY" || -z "$AWS_SECRET_KEY"]; then
	sudo sh 20-aws-cli.sh "${AWS_ACCESS_KEY}" "${AWS_SECRET_KEY}"
fi

# Add SysInfo MOTD
sudo sh 25-add-motd-system-info.sh

# Add PHP 7.4
sudo sh 30-php-7.4.sh

# Add PHP 8.1
sudo sh 32-php-8.1.sh

# Add MariaDB 10.5
sudo sh 34-mariadb-10.5.sh


# Add Node 18.x
sudo sh 40-node-js-18.sh

# Add NPM Packages
sudo sh 42-npm-install-less-sass.sh



# Add virtualmin
if [[ ! -z $VMIN_USER && ! -z $VMIN_PASSWORD ]]; then
	sudo sh 50-virtualmin-installer.sh "${DOMAIN}" "${VMIN_USER}" "${VMIN_PASSWORD}"
else
	sudo sh 50-virtualmin-installer.sh "${DOMAIN}"
fi

# Run the Virtualmin Post-Install Wizard
sudo sh 52-virtualmin-post-install-wizard-settings.sh "${MYSQL_PASSWORD}"

# Run the Virtualmin Post-Install Wizard
sudo sh 54-virtualmin-features.sh

# Create a virtual site for the default domain
sudo sh 56-create-default-domain.sh "${DOMAIN}" "${WEBMIN_PASSWORD}"

# Tweak some PHP INI settings
sudo sh 60-php-ini-tweaks.sh

# Enable 2FA
sudo 65-enable-2fa.sh

# Harden postfix
sudo 70-harden-postfix.sh


printf "\n"
printf "|| RALVIN has completed \n"
printf "|| ========================================================\n"
printf "|| FQDN:                           ${DOMAIN} \n"
printf "|| Sudo user:                      ${SUDO_USER} \n"
printf "|| Sudo password:                  ${SUDO_PASSWORD} \n"
printf "|| Public key:                     ${PUBKEY} \n"
printf "|| MySQL root password:            ${MYSQL_PASSWORD} \n"
printf "|| Webmin default domain password: ${WEBMIN_PASSWORD} \n"
printf "|| Virtualmin user:                ${VMIN_USER} \n"
printf "|| Virtualmin password:            ${VMIN_PASSWORD} \n"
printf "|| Virtualmin panel:               https://${DOMAIN}:10000 \n"

