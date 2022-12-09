#!/bin/bash

# Make sure we're root.
if (( EUID != 0 )); then
    printf '%s\n' \
        "You must run this script as root.  Either use sudo or 'su -c ${0}'" >&2
    exit 1
fi



# ███████╗███████╗████████╗██╗   ██╗██████╗     ██╗   ██╗ █████╗ ██████╗ ███████╗
# ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗    ██║   ██║██╔══██╗██╔══██╗██╔════╝
# ███████╗█████╗     ██║   ██║   ██║██████╔╝    ██║   ██║███████║██████╔╝███████╗
# ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝     ╚██╗ ██╔╝██╔══██║██╔══██╗╚════██║
# ███████║███████╗   ██║   ╚██████╔╝██║          ╚████╔╝ ██║  ██║██║  ██║███████║
# ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝           ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#                                                                                
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

declare AWS_PORTS=(22 25 80 443 465 587 993 10000 20000)



# ██████╗  █████╗ ██████╗ ███████╗███████╗    ██████╗  █████╗ ██████╗  █████╗ ███╗   ███╗███████╗
# ██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝    ██╔══██╗██╔══██╗██╔══██╗██╔══██╗████╗ ████║██╔════╝
# ██████╔╝███████║██████╔╝███████╗█████╗      ██████╔╝███████║██████╔╝███████║██╔████╔██║███████╗
# ██╔═══╝ ██╔══██║██╔══██╗╚════██║██╔══╝      ██╔═══╝ ██╔══██║██╔══██╗██╔══██║██║╚██╔╝██║╚════██║
# ██║     ██║  ██║██║  ██║███████║███████╗    ██║     ██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║███████║
# ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
#                                                                                                
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



#  ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗    ██████╗  █████╗ ██████╗  █████╗ ███╗   ███╗███████╗
# ██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝    ██╔══██╗██╔══██╗██╔══██╗██╔══██╗████╗ ████║██╔════╝
# ██║     ███████║█████╗  ██║     █████╔╝     ██████╔╝███████║██████╔╝███████║██╔████╔██║███████╗
# ██║     ██╔══██║██╔══╝  ██║     ██╔═██╗     ██╔═══╝ ██╔══██║██╔══██╗██╔══██║██║╚██╔╝██║╚════██║
# ╚██████╗██║  ██║███████╗╚██████╗██║  ██╗    ██║     ██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║███████║
#  ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
#                                                                                                
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
	SUDO_USER="rocky"
	read -e -p "|| Enter a name for the sudo user account: " -i "${SUDO_USER}" SUDO_USER
fi

# Check we have a password to use for the Virtualmin admin
if [ -z "$SUDO_PASSWORD" ]; then
	SUDO_PASSWORD=$(date +%s|sha256sum|base64|head -c 32)
	read -e -p "|| Enter a password for the sudo user account: " -i "${SUDO_PASSWORD}" SUDO_PASSWORD
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


# ----------------------------------------------------------------


#  █████╗ ██████╗ ██████╗     ███████╗██╗   ██╗██████╗  ██████╗     ██╗   ██╗███████╗███████╗██████╗ 
# ██╔══██╗██╔══██╗██╔══██╗    ██╔════╝██║   ██║██╔══██╗██╔═══██╗    ██║   ██║██╔════╝██╔════╝██╔══██╗
# ███████║██║  ██║██║  ██║    ███████╗██║   ██║██║  ██║██║   ██║    ██║   ██║███████╗█████╗  ██████╔╝
# ██╔══██║██║  ██║██║  ██║    ╚════██║██║   ██║██║  ██║██║   ██║    ██║   ██║╚════██║██╔══╝  ██╔══██╗
# ██║  ██║██████╔╝██████╔╝    ███████║╚██████╔╝██████╔╝╚██████╔╝    ╚██████╔╝███████║███████╗██║  ██║
# ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚══════╝ ╚═════╝ ╚═════╝  ╚═════╝      ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝
#
# Logging
declare PREFIX="RALVIN | create-sudo-user |"

if [ ! -z "${SUDO_USER}" || ! -z "${SUDO_PASSWORD}"]; then

	# Check if the user account already exists
	if id "$1" &>/dev/null; then
		echo "${PREFIX} User already exists" >> ./RALVIN.log
	else
		# Add the user account, and set the password
		useradd ${SUDO_USER}
		echo "${PREFIX} Created user: ${SUDO_USER}" >> ./RALVIN.log

		echo "${SUDO_PASSWORD}" | passwd "${SUDO_USER}" --stdin
		echo "${PREFIX} Updated password for user: ${SUDO_USER}" >> ./RALVIN.log
	fi

	# Add the uset to the wheel group
	usermod -aG wheel ${SUDO_USER}
	echo "${PREFIX} Added user ${SUDO_USER} to wheel group" >> ./RALVIN.log

	# Optional: disable password entry for sudo use:
	#echo "${SUDO_USER} ALL=(ALL) NOPASSWD: ALL" | sudo tee --append /etc/sudoers
else
	echo "${PREFIX} Can't create sudo user, missing username or password" >> ./RALVIN.log
fi



#  █████╗ ██████╗ ██████╗     ██████╗ ██╗   ██╗██████╗ ██╗  ██╗███████╗██╗   ██╗
# ██╔══██╗██╔══██╗██╔══██╗    ██╔══██╗██║   ██║██╔══██╗██║ ██╔╝██╔════╝╚██╗ ██╔╝
# ███████║██║  ██║██║  ██║    ██████╔╝██║   ██║██████╔╝█████╔╝ █████╗   ╚████╔╝ 
# ██╔══██║██║  ██║██║  ██║    ██╔═══╝ ██║   ██║██╔══██╗██╔═██╗ ██╔══╝    ╚██╔╝  
# ██║  ██║██████╔╝██████╔╝    ██║     ╚██████╔╝██████╔╝██║  ██╗███████╗   ██║   
# ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚═╝      ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝   ╚═╝   
#
# Logging
declare PREFIX="RALVIN | add-public-key |"

if [ -z "$PUBKEY" && ! -z "${SUDO_USER}" ]; then
	echo "${PREFIX} Skipping pubkey (none provided)" >> ./RALVIN.log
else
	$PATH = "/home/${SUDO_USER}/.ssh"

	mkdir ${PATH}
	chmod 700 ${PATH}
	touch "${PATH}/authorized_keys"
	chmod 600 "${PATH}/authorized_keys"
	echo "${2}" tee --append "${PATH}/authorized_keys"
	chown -R ${SUDO_USER}:${SUDO_USER} ${PATH}

	echo "${PREFIX}  Added pubkey to ${PATH}/authorized_keys: ${PUBKEY}" >> ./RALVIN.log
fi



# ██╗  ██╗ █████╗ ██████╗ ██████╗ ███████╗███╗   ██╗    ███████╗███████╗██╗  ██╗
# ██║  ██║██╔══██╗██╔══██╗██╔══██╗██╔════╝████╗  ██║    ██╔════╝██╔════╝██║  ██║
# ███████║███████║██████╔╝██║  ██║█████╗  ██╔██╗ ██║    ███████╗███████╗███████║
# ██╔══██║██╔══██║██╔══██╗██║  ██║██╔══╝  ██║╚██╗██║    ╚════██║╚════██║██╔══██║
# ██║  ██║██║  ██║██║  ██║██████╔╝███████╗██║ ╚████║    ███████║███████║██║  ██║
# ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝    ╚══════╝╚══════╝╚═╝  ╚═╝
#
# Logging
declare PREFIX="RALVIN | harden-ssh |"

# Change the port used for SSH
if [ ! -z "$1" ]; then
	echo "${PREFIX} SSH port changed to ${SSH_PORT}" >> ./RALVIN.log
	sed -i 's/#\?\(Port\s*\).*$/\1 ${SSH_PORT}/' /etc/ssh/sshd_config
fi

# Disable weak authentication
sed -i 's/#\?\(ChallengeResponseAuthentication\s*\).*$/\1 no/' /etc/ssh/sshd_config
sed -i 's/#\?\(PasswordAuthentication\s*\).*$/\1 no/' /etc/ssh/sshd_config

# Disable root logins
sed -i 's/#\?\(PermitRootLogin\s*\).*$/\1 no/' /etc/ssh/sshd_config

# Enable PAM
sed -i 's/#\?\(UsePAM\s*\).*$/\1 yes/' /etc/ssh/sshd_config

# Restart SSH Daemon
systemctl reload sshd

echo "${PREFIX} SSH Daemon restarted" >> ./RALVIN.log



#  ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗ ██╗   ██╗██████╗ ███████╗    ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
# ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝ ██║   ██║██╔══██╗██╔════╝    ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
# ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗██║   ██║██████╔╝█████╗      ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ 
# ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║██║   ██║██╔══██╗██╔══╝      ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ 
# ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝╚██████╔╝██║  ██║███████╗    ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
#  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
#
# Logging   
declare PREFIX="RALVIN | hostname-setup |"

# Set correct hostname
hostnamectl set-hostname --static "${DOMAIN}"
echo "${PREFIX} hostname set to: ${DOMAIN}" >> ./RALVIN.log

# Add self to DNS lookup servers (needed for virtualmin)
echo "prepend domain-name-servers 127.0.0.1;" | sudo tee -a /etc/dhcp/dhclient.conf

# Check for AWS cloud config file
$CLOUD_CFG_FILE = "/etc/cloud/cloud.cfg"
if test -f "$CLOUD_CFG_FILE"; then
	echo "preserve_hostname: true" | sudo tee -a $CLOUD_CFG_FILE
	echo "${PREFIX} AWS preserve_hostname set" >> ./RALVIN.log
fi

# Retart the network
systemctl restart NetworkManager



# ██████╗ ███╗   ██╗███████╗    ██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗
# ██╔══██╗████╗  ██║██╔════╝    ██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
# ██║  ██║██╔██╗ ██║█████╗      ██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗  
# ██║  ██║██║╚██╗██║██╔══╝      ██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝  
# ██████╔╝██║ ╚████║██║         ╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗
# ╚═════╝ ╚═╝  ╚═══╝╚═╝          ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝
#
# Logging
declare PREFIX="RALVIN | dnf-update |"

# dnf update
dnf update -y
echo "${PREFIX} Updated existing packages" >> ./RALVIN.log



# ██████╗ ███╗   ██╗███████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     
# ██╔══██╗████╗  ██║██╔════╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     
# ██║  ██║██╔██╗ ██║█████╗      ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     
# ██║  ██║██║╚██╗██║██╔══╝      ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     
# ██████╔╝██║ ╚████║██║         ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
# ╚═════╝ ╚═╝  ╚═══╝╚═╝         ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
#                
# Logging
declare PREFIX="RALVIN | dnf-install |"                                                           

# Add epel-release
dnf install -y epel-release
echo "${PREFIX} Installed package: epel-release" >> ./RALVIN.log

# Add other dependencies
PACKAGES=""
PACKAGES="${PACKAGES} tmux wget nano gcc gcc-c++ gem git"
PACKAGES="${PACKAGES} htop lm_sensors make ncdu perl perl-Authen-PAM"
PACKAGES="${PACKAGES} perl-CPAN ruby-devel rubygems scl-utils util-linux"
PACKAGES="${PACKAGES} zip unzip"

dnf install -y $PACKAGES
echo "${PREFIX} Installed packages:" >> ./RALVIN.log
echo "${PREFIX} ${PACKAGES}" >> ./RALVIN.log



#  █████╗ ██████╗ ██████╗      █████╗ ██╗    ██╗███████╗       ██████╗██╗     ██╗
# ██╔══██╗██╔══██╗██╔══██╗    ██╔══██╗██║    ██║██╔════╝      ██╔════╝██║     ██║
# ███████║██║  ██║██║  ██║    ███████║██║ █╗ ██║███████╗█████╗██║     ██║     ██║
# ██╔══██║██║  ██║██║  ██║    ██╔══██║██║███╗██║╚════██║╚════╝██║     ██║     ██║
# ██║  ██║██████╔╝██████╔╝    ██║  ██║╚███╔███╔╝███████║      ╚██████╗███████╗██║
# ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚═╝  ╚═╝ ╚══╝╚══╝ ╚══════╝       ╚═════╝╚══════╝╚═╝
#                                                                                
# Logging
declare PREFIX="RALVIN | aws-cli |"

# Fetch and install AWS CLI v2
if [ ! -f /usr/local/bin/aws ]; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -o -q awscliv2.zip
    rm awscliv2.zip
    sudo ./aws/install
    rm -rf ./aws
    echo "${PREFIX} Installed aws-cli $(/usr/local/bin/aws --version)" >> ./RALVIN.log
fi

# add aws-cli credentials if provided
if [[ ! -z "${AWS_ACCESS_KEY}" && ! -z "${AWS_SECRET_KEY}" ]]; then
    declare INSTANCE_REGION
    declare INSTANCE_ID
    declare INSTANCE_NAME
    declare PROTOCOL

    #generate credntials file
	[ ! -d ~/.aws ] && mkdir ~/.aws # make dir if not exist
	if [ ! -f ~/.aws/credentials ]; then
		touch ~/.aws/credentials 
		echo "[default]" >> ~/.aws/credentials
		echo "aws_access_key_id=${AWS_ACCESS_KEY}" >> ~/.aws/credentials
		echo "aws_secret_access_key=${AWS_SECRET_KEY}" >> ~/.aws/credentials
	fi
    
    # get info on this instance
    INSTANCE_REGION=$(/usr/local/bin/aws configure list | grep region | awk '{print $2}')
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    INSTANCE_NAME=$(/usr/local/bin/aws lightsail get-instances --query "instances[?contains(supportCode,'`curl -s http://169.254.169.254/latest/meta-data/instance-id`')].name" --output text)
    echo "${PREFIX} Configured to control instance ${INSTANCE_NAME} ${INSTANCE_ID} running on ${INSTANCE_REGION}" >> ./RALVIN.log

    # generate config file
	if [ ! -f ~/.aws/config ]; then
		touch ~/.aws/config         
        echo "[default]" >> ~/.aws/config
        echo "region=${INSTANCE_REGION}" >> ~/.aws/config
        echo "output=text" >> ~/.aws/config
    fi

    # Open Ports
	# AWS_PORTS are declared at the top of the script
    echo "${PREFIX} Opening ports ${AWS_PORTS[@]}" >> ./RALVIN.log
    PROTOCOL="tcp"

    for PORT in ${AWS_PORTS[@]}; do
        # using "both" seems to cause a bug that removes all ports. fix this later.
        
        # if [ "$PORT" -gt "1000" ]; then
        #     PROTOCOL="tcp"
        # else
        #     PROTOCOL="both"
        # fi

        /usr/local/bin/aws lightsail open-instance-public-ports --cli-input-json "{
            \"portInfo\": {
                \"fromPort\": ${PORT},
                \"toPort\": ${PORT},
                \"protocol\": \"${PROTOCOL}\"
            },
            \"instanceName\": \"${INSTANCE_NAME}\"
        }" | grep '"status": "Succeeded"' &> /dev/null

        if [ $? != 0 ]; then
            echo "${PREFIX} Failed to open port ${PORT}" >> ./RALVIN.log
        fi
    done
else
    echo "${PREFIX} No AWS CLI credentials provided. Unable to configure ports" >> ./RALVIN.log
fi



#  █████╗ ██████╗ ██████╗     ███████╗██╗   ██╗███████╗██╗███╗   ██╗███████╗ ██████╗     ███╗   ███╗ ██████╗ ████████╗██████╗ 
# ██╔══██╗██╔══██╗██╔══██╗    ██╔════╝╚██╗ ██╔╝██╔════╝██║████╗  ██║██╔════╝██╔═══██╗    ████╗ ████║██╔═══██╗╚══██╔══╝██╔══██╗
# ███████║██║  ██║██║  ██║    ███████╗ ╚████╔╝ ███████╗██║██╔██╗ ██║█████╗  ██║   ██║    ██╔████╔██║██║   ██║   ██║   ██║  ██║
# ██╔══██║██║  ██║██║  ██║    ╚════██║  ╚██╔╝  ╚════██║██║██║╚██╗██║██╔══╝  ██║   ██║    ██║╚██╔╝██║██║   ██║   ██║   ██║  ██║
# ██║  ██║██████╔╝██████╔╝    ███████║   ██║   ███████║██║██║ ╚████║██║     ╚██████╔╝    ██║ ╚═╝ ██║╚██████╔╝   ██║   ██████╔╝
# ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚══════╝   ╚═╝   ╚══════╝╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝     ╚═╝     ╚═╝ ╚═════╝    ╚═╝   ╚═════╝ 
#   
# Logging                           
declare PREFIX="RALVIN | add-motd |"

sed -i 's/#\?\(PrintMotd\s*\).*$/\1 no/' /etc/ssh/sshd_config
echo "${PREFIX} Updated sshd_config" >> ./RALVIN.log

cp ./resources/motd.ls.sh /etc/profile.d/sysinfo.motd.sh
echo "${PREFIX} Installed and enabled SysInfo MotD" >> ./RALVIN.log

chmod +x /etc/profile.d/sysinfo.motd.sh
echo "${PREFIX} SSH Daemon restarted" >> ./RALVIN.log

systemctl restart sshd




# ██████╗ ██╗  ██╗██████╗     ███████╗██╗  ██╗
# ██╔══██╗██║  ██║██╔══██╗    ╚════██║██║  ██║
# ██████╔╝███████║██████╔╝        ██╔╝███████║
# ██╔═══╝ ██╔══██║██╔═══╝        ██╔╝ ╚════██║
# ██║     ██║  ██║██║            ██║██╗    ██║
# ╚═╝     ╚═╝  ╚═╝╚═╝            ╚═╝╚═╝    ╚═╝
#
# Logging
declare PREFIX="RALVIN | php-7.4 |"

dnf module enable php:7.4 -y
echo "${PREFIX} Enabled PHP7.4 Repo" >> ./RALVIN.log

PACKAGES=""
PACKAGES="${PACKAGES} php php-fpm php-bcmath php-cli php-common php-curl php-devel"
PACKAGES="${PACKAGES} php-fpm php-gd php-gmp php-intl php-json php-mbstring php-mysqlnd"
PACKAGES="${PACKAGES} php-opcache php-pdo php-pear php-pecl-apcu php-pecl-zip php-process"
PACKAGES="${PACKAGES} php-simplexml php-soap php-xml php-xmlrpc"

dnf install -y $PACKAGES

echo "${PREFIX} Installed PHP 7.4: $( /usr/bin/php -v | head -n 1)" >> ./RALVIN.log
echo "${PREFIX} Installed packages: ${PACKAGES}" >> ./RALVIN.log

# (Optional) Make this the default CLI version
#ln -s /usr/bin/php74 /usr/bin/php
#echo "${PREFIX} Created link in /usr/bin/php" >> ./RALVIN.log



# ██████╗ ██╗  ██╗██████╗      █████╗    ██╗
# ██╔══██╗██║  ██║██╔══██╗    ██╔══██╗  ███║
# ██████╔╝███████║██████╔╝    ╚█████╔╝  ╚██║
# ██╔═══╝ ██╔══██║██╔═══╝     ██╔══██╗   ██║
# ██║     ██║  ██║██║         ╚█████╔╝██╗██║
# ╚═╝     ╚═╝  ╚═╝╚═╝          ╚════╝ ╚═╝╚═╝
#                                           
# Logging
declare PREFIX="RALVIN | php-8.1 |"

# Setup Remi repo
dnf config-manager --set-enabled powertools
dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
echo "${PREFIX} Enabled PHP Remi 8.1 Repo" >> ./RALVIN.log

# Configure packages to install
PACKAGES=""
PACKAGES="${PACKAGES} php81 php81-php php81-php-fpm php81-php-bcmath php81-php-cli php81-php-common"
PACKAGES="${PACKAGES} php81-php-curl php81-php-devel php81-php-fpm php81-php-gd php81-php-gmp php81-php-intl php81-php-json"
PACKAGES="${PACKAGES} php81-php-mbstring php81-php-mcrypt php81-php-mysqlnd php81-php-opcache php81-php-pdo php81-php-pear"
PACKAGES="${PACKAGES} php81-php-pecl-apcu php81-php-pecl-geoip php81-php-pecl-imagick php81-php-pecl-json-post"
PACKAGES="${PACKAGES} php81-php-pecl-memcache php81-php-pecl-xmldiff php81-php-pecl-zip php81-php-process php81-php-pspell"
PACKAGES="${PACKAGES} php81-php-simplexml php81-php-soap php81-php-tidy php81-php-xml php81-php-xmlrpc"

dnf install -y $PACKAGES

echo "${PREFIX} Installed Remi PHP 8.1: $( /usr/bin/php81 -v | head -n 1)" >> ./RALVIN.log
echo "${PREFIX} Installed packages: ${PACKAGES}" >> ./RALVIN.log

# (Optional) Make this the default CLI php version
#ln -s /usr/bin/php74 /usr/bin/php
#echo "${PREFIX} Created link in /usr/bin/php" >> ./RALVIN.log



# ███╗   ███╗ █████╗ ██████╗ ██╗ █████╗ ██████╗ ██████╗      ██╗ ██████╗    ███████╗
# ████╗ ████║██╔══██╗██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗    ███║██╔═████╗   ██╔════╝
# ██╔████╔██║███████║██████╔╝██║███████║██║  ██║██████╔╝    ╚██║██║██╔██║   ███████╗
# ██║╚██╔╝██║██╔══██║██╔══██╗██║██╔══██║██║  ██║██╔══██╗     ██║████╔╝██║   ╚════██║
# ██║ ╚═╝ ██║██║  ██║██║  ██║██║██║  ██║██████╔╝██████╔╝     ██║╚██████╔╝██╗███████║
# ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═════╝ ╚═════╝      ╚═╝ ╚═════╝ ╚═╝╚══════╝
#             
# Logging
declare PREFIX="RALVIN | mariadb-10.5 |"                                                                      

# Install MariaDB 10.5
dnf module enable -y mariadb:10.5
dnf install -y mariadb

echo "${PREFIX} Upgraded MariaDB to $(mariadb -V)" >> ./RALVIN.log
echo "${PREFIX} MariaDB service restarted " >> ./RALVIN.log



#  █████╗ ██████╗ ██████╗     ███╗   ██╗ ██████╗ ██████╗ ███████╗     ██╗ █████╗    ██╗  ██╗
# ██╔══██╗██╔══██╗██╔══██╗    ████╗  ██║██╔═══██╗██╔══██╗██╔════╝    ███║██╔══██╗   ╚██╗██╔╝
# ███████║██║  ██║██║  ██║    ██╔██╗ ██║██║   ██║██║  ██║█████╗      ╚██║╚█████╔╝    ╚███╔╝ 
# ██╔══██║██║  ██║██║  ██║    ██║╚██╗██║██║   ██║██║  ██║██╔══╝       ██║██╔══██╗    ██╔██╗ 
# ██║  ██║██████╔╝██████╔╝    ██║ ╚████║╚██████╔╝██████╔╝███████╗     ██║╚█████╔╝██╗██╔╝ ██╗
# ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝     ╚═╝ ╚════╝ ╚═╝╚═╝  ╚═╝
#

# Install NodeJS v18.x
dnf module enable -y nodejs:18
dnf install -y nodejs

# Logging
declare PREFIX="RALVIN | node-js |"
echo "${PREFIX} Installed NodeJS $(node -v)" >> ./RALVIN.log
echo "${PREFIX} Installed NPM $(npm -v)" >> ./RALVIN.log



#  █████╗ ██████╗ ██████╗     ███╗   ██╗██████╗ ███╗   ███╗    ██████╗  █████╗  ██████╗██╗  ██╗ █████╗  ██████╗ ███████╗███████╗
# ██╔══██╗██╔══██╗██╔══██╗    ████╗  ██║██╔══██╗████╗ ████║    ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔════╝ ██╔════╝██╔════╝
# ███████║██║  ██║██║  ██║    ██╔██╗ ██║██████╔╝██╔████╔██║    ██████╔╝███████║██║     █████╔╝ ███████║██║  ███╗█████╗  ███████╗
# ██╔══██║██║  ██║██║  ██║    ██║╚██╗██║██╔═══╝ ██║╚██╔╝██║    ██╔═══╝ ██╔══██║██║     ██╔═██╗ ██╔══██║██║   ██║██╔══╝  ╚════██║
# ██║  ██║██████╔╝██████╔╝    ██║ ╚████║██║     ██║ ╚═╝ ██║    ██║     ██║  ██║╚██████╗██║  ██╗██║  ██║╚██████╔╝███████╗███████║
# ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚═╝  ╚═══╝╚═╝     ╚═╝     ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝
#                                                                                                                               

# Install LESS and SASS preprocessors
npm install -g less sass

# Logging
declare PREFIX="RALVIN | npm-install |"
echo "${PREFIX} LESS and SASS installed via NPM" >> ./RALVIN.log



# ██╗   ██╗██╗██████╗ ████████╗██╗   ██╗ █████╗ ██╗     ███╗   ███╗██╗███╗   ██╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     
# ██║   ██║██║██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██║     ████╗ ████║██║████╗  ██║    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     
# ██║   ██║██║██████╔╝   ██║   ██║   ██║███████║██║     ██╔████╔██║██║██╔██╗ ██║    ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     
# ╚██╗ ██╔╝██║██╔══██╗   ██║   ██║   ██║██╔══██║██║     ██║╚██╔╝██║██║██║╚██╗██║    ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     
#  ╚████╔╝ ██║██║  ██║   ██║   ╚██████╔╝██║  ██║███████╗██║ ╚═╝ ██║██║██║ ╚████║    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
#   ╚═══╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
## Logging
declare PREFIX="RALVIN | virtualmin-installer |"

# Get the installer
curl -o ./virtualmin-installer.sh http://software.virtualmin.com/gpl/scripts/install.sh
chmod +x ./virtualmin-installer.sh
echo "${PREFIX} got latest installer" >> ./RALVIN.log

# Run the installer
echo "${PREFIX} triggering install with hostname ${DOMAIN}" >> ./RALVIN.log
./virtualmin-installer.sh --hostname "${DOMAIN}" --force
echo "${PREFIX} finished install with hostname ${DOMAIN}" >> ./RALVIN.log


# Update the password
if [[ ! -z $VMIN_USER && ! -z $VMIN_PASSWORD ]]; then
	sudo /usr/libexec/webmin/changepass.pl /etc/webmin $VMIN_USER $VMIN_PASSWORD
	echo "${PREFIX} password updated for Virtualmin user ${VMIN_USER}" >> ./RALVIN.log
fi



# ██╗   ██╗██╗██████╗ ████████╗██╗   ██╗ █████╗ ██╗     ███╗   ███╗██╗███╗   ██╗    ██████╗  ██████╗ ███████╗████████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     
# ██║   ██║██║██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██║     ████╗ ████║██║████╗  ██║    ██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     
# ██║   ██║██║██████╔╝   ██║   ██║   ██║███████║██║     ██╔████╔██║██║██╔██╗ ██║    ██████╔╝██║   ██║███████╗   ██║       ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     
# ╚██╗ ██╔╝██║██╔══██╗   ██║   ██║   ██║██╔══██║██║     ██║╚██╔╝██║██║██║╚██╗██║    ██╔═══╝ ██║   ██║╚════██║   ██║       ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     
#  ╚████╔╝ ██║██║  ██║   ██║   ╚██████╔╝██║  ██║███████╗██║ ╚═╝ ██║██║██║ ╚████║    ██║     ╚██████╔╝███████║   ██║       ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
#   ╚═══╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝    ╚═╝      ╚═════╝ ╚══════╝   ╚═╝       ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
#
# Logging
declare PREFIX="RALVIN | virtualmin-post-install |"

declare CONFIG="/etc/webmin/virtual-server/config"

# get system
declare -i SYS_MEMORY=$(grep MemTotal /proc/meminfo|awk '{print $2}')/1000

# Choose the mysql memory based on the system memory
declare MYSQL_MEMORY

if ((SYS_MEMORY < 512)); then
	MYSQL_MEMORY="small"
elif ((SYS_MEMORY < 1024)); then
	MYSQL_MEMORY="medium"
elif ((SYS_MEMORY < 2048)); then
	MYSQL_MEMORY="large"
elif ((SYS_MEMORY > 2047)); then
	MYSQL_MEMORY="huge"
fi

# Enable MySQL server
sed -i 's/mysql=.*/mysql=1/' $CONFIG

# Update password for MySQL root user
# This needs to be done BEFORE you upgrade to MariaDB 10.4+ due to the bug described at https://www.virtualmin.com/node/64694
if [ ! -z "${MYSQL_PASSWORD}" ]; then
	virtualmin set-mysql-pass --user root --pass "${MYSQL_PASSWORD}"
	echo "${PREFIX} Updated root password for MySQL" >> ./RALVIN.log
fi

# Set MySQL server memory size
sed_param=s/mysql_size=.*/mysql_size=${MYSQL_MEMORY}/  
sed -i "$sed_param" $CONFIG
echo "${PREFIX} MySQL memory setting is ${MYSQL_MEMORY}" >> ./RALVIN.log


# Enable preloading of virtualmin libraries
sed -i 's/preload_mode=.*/preload_mode=1/' $CONFIG
echo "${PREFIX} Enabled Virtualmin library preloading" >> ./RALVIN.log

# Enable ClamAV server
sed -i 's/virus=.*/virus=1/' $CONFIG
echo "${PREFIX} Enabled ClamAV server" >> ./RALVIN.log

# Enable SpamAssassin server
sed -i 's/spam=.*/spam=1/' $CONFIG
echo "${PREFIX} Enabled SpamAssassin server" >> ./RALVIN.log

# Enable quotas

# This is work in progress. Quotas need to be enabled in grub, which requires a bit of regex-fu beyond me. 
# I need to prepend `uquota,gquota,` to the rootflags parameter if it exists in GRUB_CMDLINE_LINUX, otherwise add it

# sudo grep -q "rootflags" /etc/default/grub && sudo sed -i "s/rootflags=/rootflags=uquota,gquota,/" /etc/default/grub || echo "rootflags not found"

# loosely converted from this snippet of https://github.com/virtualmin/virtualmin-gpl/blob/master/wizard-lib.pl

#	my %grub;
#	&read_env_file($grubfile, \%grub) ||
#		return &text('wizard_egrubfile', "<tt>$grubfile</tt>");
#	my $v = $grub{'GRUB_CMDLINE_LINUX'};
#	$v || return &text('wizard_egrubline', "<tt>GRUB_CMDLINE_LINUX</tt>");
#	if ($v =~ /rootflags=(\S+)/) {
#		$v =~ s/rootflags=(\S+)/rootflags=$1,uquota,gquota/;
#		}
#	else {
#		$v .= " rootflags=uquota,gquota";
#		}
#

# Update the config file to let it know quotas are enabled
#sed -i 's/quotas=.*/quotas=1/' $CONFIG

#echo "${PREFIX} Enabled quotas" >> ./RALVIN.log 

# Enable hashed passwords
sed -i 's/hashpass=.*/hashpass=1/' $CONFIG
echo "${PREFIX} Enabled hashed passwords" >> ./RALVIN.log

# Enable wizard_run flag
echo "wizard_run=1" >> $CONFIG
sed -i 's/wizard_run=.*/wizard_run=1/' $CONFIG
echo "${PREFIX} Manually added wizard_run flag" >> ./RALVIN.log

# Redirect non-SSL calls to the admin panel to SSL
sed -i 's/ssl_redirect=.*/ssl_redirect=1/' /etc/webmin/miniserv.conf
echo "${PREFIX} Enabled non-SSL to SSL redirect for Webmin panel" >> ./RALVIN.log

# Enable SSL by default
virtualmin set-global-feature --default-on ssl
echo "${PREFIX} SSL enabled" >> ./RALVIN.log

# Disable AWstats by default
virtualmin set-global-feature --default-off virtualmin-awstats 
echo "${PREFIX} AWStats disabled" >> ./RALVIN.log

# Disable DAV by default
virtualmin set-global-feature --default-off virtualmin-dav 
echo "${PREFIX} DAV disabled" >> ./RALVIN.log

# Change autoconfig script to have hard-coded STARTTLS
virtualmin modify-mail --all-domains --autoconfig
sudo virtualmin modify-template --id 0 --setting autoconfig --value "$(cat ./resources/autoconfig.xml | tr '\n' ' ')"
sudo virtualmin modify-template --id 0 --setting autodiscover --value "$(cat ./resources/autodiscover.xml | tr '\n' ' ')"
echo "${PREFIX} autoconfig enabled and STARTTLS hard-coded" >> ./RALVIN.log


# Check config?

# fin
echo "${PREFIX} Virtualmin Post-Install Wizard setup complete" >> ./RALVIN.log



# ██████╗ ███████╗███████╗ █████╗ ██╗   ██╗██╗  ████████╗    ██████╗  ██████╗ ███╗   ███╗ █████╗ ██╗███╗   ██╗
# ██╔══██╗██╔════╝██╔════╝██╔══██╗██║   ██║██║  ╚══██╔══╝    ██╔══██╗██╔═══██╗████╗ ████║██╔══██╗██║████╗  ██║
# ██║  ██║█████╗  █████╗  ███████║██║   ██║██║     ██║       ██║  ██║██║   ██║██╔████╔██║███████║██║██╔██╗ ██║
# ██║  ██║██╔══╝  ██╔══╝  ██╔══██║██║   ██║██║     ██║       ██║  ██║██║   ██║██║╚██╔╝██║██╔══██║██║██║╚██╗██║
# ██████╔╝███████╗██║     ██║  ██║╚██████╔╝███████╗██║       ██████╔╝╚██████╔╝██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
# ╚═════╝ ╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝       ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
#
# Logging
declare PREFIX="RALVIN | create-default-domain |"

# Create a virtual site for the default domain
virtualmin create-domain --domain "${DOMAIN}" --pass "${WEBMIN_PASSWORD}" --default-features

declare HOME_DIR=$(virtualmin list-domains | grep "${DOMAIN}" | awk -F" " '{print $2}')

if [ ! -z "$HOME_DIR" ]; then
	# Copy default server status page
	cp ./resources/index.html "/home/${HOME_DIR}/public_html/index.html"
	echo "${PREFIX} Created /home/${HOME_DIR}/public_html/index.html" >> ./RALVIN.log
	
	# Update status page with correct domain
	sed -i -e "s/example\.com/${DOMAIN}/g" "/home/${HOME_DIR}/public_html/index.html"
fi

# Generate and install lets encrypt certificate
virtualmin generate-letsencrypt-cert --domain "$1" >> RALVIN.ssl.log

virtualmin install-service-cert --domain "$1" --service postfix >> RALVIN.ssl.log
virtualmin install-service-cert --domain "$1" --service usermin >> RALVIN.ssl.log
virtualmin install-service-cert --domain "$1" --service webmin >> RALVIN.ssl.log
virtualmin install-service-cert --domain "$1" --service dovecot >> RALVIN.ssl.log
virtualmin install-service-cert --domain "$1" --service proftpd >> RALVIN.ssl.log

echo "${PREFIX} LetsEncrypt certificate requested and copied to services (see RALVIN.ssl.log for more info)" >> ./RALVIN.log



# ██████╗ ██╗  ██╗██████╗     ██╗███╗   ██╗██╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗
# ██╔══██╗██║  ██║██╔══██╗    ██║████╗  ██║██║    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝
# ██████╔╝███████║██████╔╝    ██║██╔██╗ ██║██║       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ ███████╗
# ██╔═══╝ ██╔══██║██╔═══╝     ██║██║╚██╗██║██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ╚════██║
# ██║     ██║  ██║██║         ██║██║ ╚████║██║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████║
# ╚═╝     ╚═╝  ╚═╝╚═╝         ╚═╝╚═╝  ╚═══╝╚═╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#
# Logging
declare PREFIX="RALVIN | php-ini-tweaks |"

# Add PHP 8.1 php.ini to webmin
echo "/etc/opt/remi/php81/php.ini" | sudo tee -a /etc/webmin/phpini/config
echo $(sudo head -c -1 /etc/webmin/phpini/config) | sudo tee /etc/webmin/phpini/config
echo "${PREFIX} Added PHP 8.1 php.ini to Webmin" >> ./RALVIN.log

# Tweaks various settings for php.ini
virtualmin modify-php-ini --all-domains --ini-name upload_max_filesize --ini-value 32M
virtualmin modify-php-ini --all-domains --ini-name post_max_size  --ini-value 32M
echo "${PREFIX} upload_max_filesize and post_max_size set to 32M" >> ./RALVIN.log

# Add GNU Terry Pratchett 
tee -a /etc/httpd/conf/httpd.conf > /dev/null <<EOT

#  ╔═╗╔╗╔╦ ╦  ╔╦╗┌─┐┬─┐┬─┐┬ ┬  ╔═╗┬─┐┌─┐┌┬┐┌─┐┬ ┬┌─┐┌┬┐┌┬┐
#  ║ ╦║║║║ ║   ║ ├┤ ├┬┘├┬┘└┬┘  ╠═╝├┬┘├─┤ │ │  ├─┤├┤  │  │ 
#  ╚═╝╝╚╝╚═╝   ╩ └─┘┴└─┴└─ ┴   ╩  ┴└─┴ ┴ ┴ └─┘┴ ┴└─┘ ┴  ┴ 
<IfModule headers_module>
  header set X-Clacks-Overhead "GNU Terry Pratchett"
</IfModule>
EOT

echo "${PREFIX} Added GNU Terry Pratchett to httpd.conf" >> ./RALVIN.log

# Restart apache
systemctl restart httpd



# ███████╗███╗   ██╗ █████╗ ██████╗ ██╗     ███████╗    ██████╗ ███████╗ █████╗ 
# ██╔════╝████╗  ██║██╔══██╗██╔══██╗██║     ██╔════╝    ╚════██╗██╔════╝██╔══██╗
# █████╗  ██╔██╗ ██║███████║██████╔╝██║     █████╗       █████╔╝█████╗  ███████║
# ██╔══╝  ██║╚██╗██║██╔══██║██╔══██╗██║     ██╔══╝      ██╔═══╝ ██╔══╝  ██╔══██║
# ███████╗██║ ╚████║██║  ██║██████╔╝███████╗███████╗    ███████╗██║     ██║  ██║
# ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝    ╚══════╝╚═╝     ╚═╝  ╚═╝
#                                                                               
# Installs the required packages to enable Google Authenticator 2FA for Webmin
# 
# Logging
declare PREFIX="RALVIN | enable-2fa |"

# Copy the CPAN config file
[[ ! -e "/root/.cpan/CPAN" ]] && mkdir -p /root/.cpan/CPAN && echo "${PREFIX} Made CPAN directory" >> ./RALVIN.log
[[ ! -e "/root/.cpan/CPAN/MyConfig.pm" ]] && cp ./resources/CPAN.pm /root/.cpan/CPAN/MyConfig.pm && chown root /root/.cpan/CPAN/MyConfig.pm && echo "${PREFIX} Copied CPAN config from template" >> ./RALVIN.log

# Install the right modules
PACKAGES="Archive::Tar Authen::OATH Digest::HMAC Digest::SHA Math::BigInt Moo Moose Module::Build Test::More Test::Needs Type::Tiny Types::Standard"
cpan install $PACKAGES
echo "${PREFIX} Installed perl packages" >> ./RALVIN.log

# Enable Google Authenticator
echo "twofactor_provider=totp" | sudo tee -a /etc/webmin/miniserv.conf
echo "${PREFIX} Enabled Google Authenticator 2FA for Webmin. You will need to enroll a user manually." >> ./RALVIN.log



# ██╗  ██╗ █████╗ ██████╗ ██████╗ ███████╗███╗   ██╗    ██████╗  ██████╗ ███████╗████████╗███████╗██╗██╗  ██╗
# ██║  ██║██╔══██╗██╔══██╗██╔══██╗██╔════╝████╗  ██║    ██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝██╔════╝██║╚██╗██╔╝
# ███████║███████║██████╔╝██║  ██║█████╗  ██╔██╗ ██║    ██████╔╝██║   ██║███████╗   ██║   █████╗  ██║ ╚███╔╝ 
# ██╔══██║██╔══██║██╔══██╗██║  ██║██╔══╝  ██║╚██╗██║    ██╔═══╝ ██║   ██║╚════██║   ██║   ██╔══╝  ██║ ██╔██╗ 
# ██║  ██║██║  ██║██║  ██║██████╔╝███████╗██║ ╚████║    ██║     ╚██████╔╝███████║   ██║   ██║     ██║██╔╝ ██╗
# ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝    ╚═╝      ╚═════╝ ╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝
#                                                                                                            
# Hardens a default Postfix install
#
# Logging
declare PREFIX="RALVIN | harden-postfix |"

# Backup the current/default config
postconf | sudo tee /root/postfix.main.cf.$(date "+%F-%T")
echo "${PREFIX} Backed up original config to /root/postfix.main.cf.$(date "+%F-%T")" >> ./RALVIN.log

# Disable verify - stop clients querying for valid users
postconf -e 'disable_vrfy_command = yes'

# Force HELO required
postconf -e 'smtpd_helo_required = yes'
postconf -e 'smtpd_helo_restrictions = permit_mynetworks permit_sasl_authenticated reject_invalid_helo_hostname reject_non_fqdn_helo_hostname reject_unknown_helo_hostname'

# Encourage the use of TLS
postconf -e 'smtp_tls_security_level = may'
postconf -e 'smtp_tls_note_starttls_offer = yes'
postconf -e 'smtp_use_tls = yes'
postconf -e 'smtpd_use_tls = yes'
postconf -e 'smtpd_tls_security_level = may'
postconf -e 'smtpd_sasl_auth_enable = yes'

# Limit the rate of incoming connections
postconf -e 'smtpd_client_connection_count_limit = 10'
postconf -e 'smtpd_client_connection_rate_limit = 60'

# Set client, recipient, relay & sender security and relay restrictions
postconf -e 'smtpd_client_restrictions = permit_mynetworks permit_sasl_authenticated reject_unauth_destination reject_rbl_client zen.spamhaus.org reject_rbl_client bl.spamcop.net reject_rbl_client cbl.abuseat.org permit'
postconf -e 'smtpd_recipient_restrictions = permit_mynetworks permit_sasl_authenticated reject_unauth_destination reject_rbl_client zen.spamhaus.org reject_rhsbl_reverse_client dbl.spamhaus.org reject_rhsbl_helo dbl.spamhaus.org reject_rhsbl_sender dbl.spamhaus.org'
postconf -e 'smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated reject_unauth_destination'
postconf -e 'smtpd_sender_restrictions = permit_mynetworks permit_sasl_authenticated reject_unknown_sender_domain'
postconf -e 'smtpd_sasl_security_options = noanonymous'

# Reload postfix
postfix reload
systemctl restart postfix
echo "${PREFIX} Postfix hardened and reloaded" >> ./RALVIN.log


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

