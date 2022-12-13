#!/bin/bash

# Make sure we're root.
if (( EUID != 0 )); then
    printf '%s\n' \
        "You must run this script as root.  Either use sudo or 'su -c ${0}'" >&2
    exit 1
fi

# Logging function
log_prefix="|| "
log_file="ralvin.log"
log() {
	echo "$log_prefix $1"

	echo "$log_prefix $1" >> $log_file
}


# ███████╗███████╗████████╗██╗   ██╗██████╗     ██╗   ██╗ █████╗ ██████╗ ███████╗
# ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗    ██║   ██║██╔══██╗██╔══██╗██╔════╝
# ███████╗█████╗     ██║   ██║   ██║██████╔╝    ██║   ██║███████║██████╔╝███████╗
# ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝     ╚██╗ ██╔╝██╔══██║██╔══██╗╚════██║
# ███████║███████╗   ██║   ╚██████╔╝██║          ╚████╔╝ ██║  ██║██║  ██║███████║
# ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝           ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#

declare -l fqdn_hostname
declare ssh_custom_port

declare -l sudo_user_name
declare sudo_user_pubkey
declare sudo_user_password

declare -l virtualmin_user
declare virtualmin_password
declare mysql_root_password

declare aws_access_key
declare aws_secret_key
declare -a aws_firewall_ports=(22 25 80 443 465 587 993 10000 20000)

read -r -d '' help_info << EOM
Rocky Amazon LightSail Virtualmin Installer (RALVIN)

More information is available at https://github.com/stom66/ralvin

Options:
    --help                                show this help info

    --domain [domain.tld]                 specify the FQDN to use as the system hostname
    --ssh-port [number]                   (optional): a custom port to use for the ssh server

    --sudo-user-name [rocky]              specify a user account to use (or create) as the sudo account
    --sudo-user-pubkey [valid pubkey]     specify an public key to be added to the authorized_keys file for the sudo user
    --sudo-user-password [random]         specify a password for the sudo account

    --mysql-root-password [random]        specify a password to use for the MySQL root user
    --virtualmin-user [root]              specify a user to enable the Vitualmin admin panel password for
    --virtualmin-password [random]        specify a password to use for the Virtualmin admin panel

    --aws-access-key [key]                (optional): aws access key to use for aws-cli
    --aws-secret-key [key]                (optional): aws secret key to use for aws-cli

EOM


# ██████╗  █████╗ ██████╗ ███████╗███████╗    ███████╗██╗      █████╗  ██████╗ ███████╗
# ██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝    ██╔════╝██║     ██╔══██╗██╔════╝ ██╔════╝
# ██████╔╝███████║██████╔╝███████╗█████╗      █████╗  ██║     ███████║██║  ███╗███████╗
# ██╔═══╝ ██╔══██║██╔══██╗╚════██║██╔══╝      ██╔══╝  ██║     ██╔══██║██║   ██║╚════██║
# ██║     ██║  ██║██║  ██║███████║███████╗    ██║     ███████╗██║  ██║╚██████╔╝███████║
# ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝     ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
#                                                                                      


# fqdn_hostname
# sudo_user_pubkey
# sudo_user_name
# sudo_user_password
# virtualmin_user
# virtualmin_password
# mysql_root_password
# aws_access_key
# aws_secret_key
# ssh_custom_port

# Parse the named flags provided to the script
while [[ $# -gt 0 ]]; do
  case $1 in
    --help)
      printf "$help_info \n"
	  exit 0
      ;;
    --fqdn-hostname)
      fqdn_hostname=$2
      shift
      shift
      ;;
    --ssh-custom-port)
      ssh_custom_port=$2
      shift
      shift
      ;;
    --sudo-user-pubkey)
      sudo_user_pubkey=$2
      shift
      shift
      ;;
    --sudo-user-name)
      sudo_user_name=$2
      shift
      shift
      ;;
    --sudo-user-password)
      sudo_user_password=$2
      shift
      shift
      ;;
    --virtualmin-user)
      virtualmin_user=$2
      shift
      shift
      ;;
    --virtualmin-password)
      virtualmin_password=$2
      shift
      shift
      ;;
    --mysql-root-password)
      mysql_root_password=$2
      shift
      shift
      ;;
    --aws-access-key)
      aws_access_key=$2
      shift
      shift
      ;;
    --aws-secret-key)
      aws_secret_key=$2
      shift
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# ██████╗ ██████╗  ██████╗ ███╗   ███╗██████╗ ████████╗    ███████╗██╗      █████╗  ██████╗ ███████╗
# ██╔══██╗██╔══██╗██╔═══██╗████╗ ████║██╔══██╗╚══██╔══╝    ██╔════╝██║     ██╔══██╗██╔════╝ ██╔════╝
# ██████╔╝██████╔╝██║   ██║██╔████╔██║██████╔╝   ██║       █████╗  ██║     ███████║██║  ███╗███████╗
# ██╔═══╝ ██╔══██╗██║   ██║██║╚██╔╝██║██╔═══╝    ██║       ██╔══╝  ██║     ██╔══██║██║   ██║╚════██║
# ██║     ██║  ██║╚██████╔╝██║ ╚═╝ ██║██║        ██║       ██║     ███████╗██║  ██║╚██████╔╝███████║
# ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝        ╚═╝       ╚═╝     ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
#                                                                                                   

log "RALVIN: checking options"
log "========================================================"


# Check we have a domain to use for configuration, prompt if not
if [ -z "$fqdn_hostname" ]; then
	read -e -p "|| Enter a valid FQDN: " -i "example.com" fqdn_hostname
else
	log "Using FQDN: $fqdn_hostname"
fi

# Quit out if the user failed to provide a FQDN
if [ -z "$fqdn_hostname" ]; then
	log "You must specify a FQDN. Script is exiting.\n"
	exit 0
fi

# Check we have a sudo user account name to create
if [ -z "$sudo_user_name" ]; then
	sudo_user_name="rocky"
	read -e -p "|| Enter a name for the sudo user account: " -i "${sudo_user_name}" sudo_user_name
else
	log "Using sudo_user_name: $sudo_user_name"
fi

# Check if the user account already exists. If it does not, prompt the user to specify a password for it:
if id -u "$sudo_user_name"  > /dev/null 2>&1; then
	log "The user account exists: ${sudo_user_name}, skipping password"
else
	# Check we have a password to use for the Virtualmin admin
	if [ -z "$sudo_user_password" ]; then
		sudo_user_password=$(date +%s|sha256sum|base64|head -c 32)
		read -e -p "|| Enter a password for the sudo user account: " -i "${sudo_user_password}" sudo_user_password
	else
		log "Using sudo_user_password: $sudo_user_password"
	fi
fi

# Check if we're using a pubkey, or request one
if [ -z "$sudo_user_pubkey" ]; then
	read -e -p "|| Enter an optional public key for ${sudo_user_name}: " -i "${sudo_user_pubkey}" sudo_user_pubkey
else
	log "Adding pubkey for ${sudo_user_name}: $sudo_user_pubkey"
fi

# Check we have a user to set the password for
if [ -z "$virtualmin_user" ]; then
	read -e -p "|| Enter a valid user to grant access to the Virtualmin admin panel: " -i "root" virtualmin_user
else
	log "Using virtualmin_user: $virtualmin_user"
fi

# Check we have a password to use for the Virtualmin admin
if [ -z "$virtualmin_password" ]; then
	virtualmin_password=$(date +%s|sha256sum|base64|head -c 32)
	read -e -p "|| Enter a password for the Virtualmin admin panel: " -i "${virtualmin_password}" virtualmin_password
else
	log "Using virtualmin_password: $virtualmin_password"
fi

# Check we have a password to set for the MySQL root user
if [ -z "$mysql_root_password" ]; then
	mysql_root_password=$(date +%s|sha256sum|sha256sum|base64|head -c 32)
	read -e -p "|| Enter a password for the MySQL root user: " -i "${mysql_root_password}" mysql_root_password
else
	log "Using mysql_root_password: $mysql_root_password"
fi

# AWS Credentials
# Check for an AWS access key
if [ -z "$aws_access_key" ]; then
	read -e -p "|| Enter an (optional) aws-cli ACCESS KEY: " -i "${aws_access_key}" aws_access_key
else
	log "Using aws_access_key: $aws_access_key"
fi

# Check for an AWS secret key
if [ -z "$aws_secret_key" ]; then
	read -e -p "|| Enter an (optional) aws-cli SECRET KEY: " -i "${aws_secret_key}" aws_secret_key
else
	log "Using aws_secret_key: $aws_secret_key"
fi

# Check for a a custom SSH port
if [ -z "$ssh_custom_port" ]; then
	ssh_custom_port=22
	read -e -p "|| Enter an (optional) custom SSH port: " -i "${ssh_custom_port}" ssh_custom_port
else
	log "Using ssh_custom_port: $ssh_custom_port"
fi


log "========================================================"
log ""

# ----------------------------------------------------------------


#  █████╗ ██████╗ ██████╗     ███████╗██╗   ██╗██████╗  ██████╗     ██╗   ██╗███████╗███████╗██████╗ 
# ██╔══██╗██╔══██╗██╔══██╗    ██╔════╝██║   ██║██╔══██╗██╔═══██╗    ██║   ██║██╔════╝██╔════╝██╔══██╗
# ███████║██║  ██║██║  ██║    ███████╗██║   ██║██║  ██║██║   ██║    ██║   ██║███████╗█████╗  ██████╔╝
# ██╔══██║██║  ██║██║  ██║    ╚════██║██║   ██║██║  ██║██║   ██║    ██║   ██║╚════██║██╔══╝  ██╔══██╗
# ██║  ██║██████╔╝██████╔╝    ███████║╚██████╔╝██████╔╝╚██████╔╝    ╚██████╔╝███████║███████╗██║  ██║
# ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚══════╝ ╚═════╝ ╚═════╝  ╚═════╝      ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝
#
# Logging
log_prefix="|| create-sudo-user |"

if [[ -n "${sudo_user_name}" && -n "${sudo_user_password}" ]]; then

	# Check if the user account already exists
	if id "${sudo_user_name}" & > /dev/null; then
		log "User already exists"
	else
		# Add the user account, and set the password
		useradd "$sudo_user_name"
		log "Created user: ${sudo_user_name}"

		echo "${sudo_user_password}" | passwd "${sudo_user_name}" --stdin
		log "Updated password for user: ${sudo_user_name}"
	fi

	# Add the uset to the wheel group
	usermod -aG wheel "${sudo_user_name}"
	log "Added user ${sudo_user_name} to wheel group"

	# Optional: disable password entry for sudo use:
	#echo "${sudo_user_name} ALL=(ALL) NOPASSWD: ALL" | sudo tee --append /etc/sudoers > /dev/null
else
	log "Can't create sudo user, missing username or password"
fi



#  █████╗ ██████╗ ██████╗     ██████╗ ██╗   ██╗██████╗ ██╗  ██╗███████╗██╗   ██╗
# ██╔══██╗██╔══██╗██╔══██╗    ██╔══██╗██║   ██║██╔══██╗██║ ██╔╝██╔════╝╚██╗ ██╔╝
# ███████║██║  ██║██║  ██║    ██████╔╝██║   ██║██████╔╝█████╔╝ █████╗   ╚████╔╝ 
# ██╔══██║██║  ██║██║  ██║    ██╔═══╝ ██║   ██║██╔══██╗██╔═██╗ ██╔══╝    ╚██╔╝  
# ██║  ██║██████╔╝██████╔╝    ██║     ╚██████╔╝██████╔╝██║  ██╗███████╗   ██║   
# ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚═╝      ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝   ╚═╝   
#
# Logging
log_prefix="|| add-public-key |"

if [ -z "${sudo_user_pubkey}" ] || [ -z "${sudo_user_name}" ]; then
	log "Skipping pubkey (none provided)"
else
	file_path="/home/${sudo_user_name}/.ssh"

	# Make the dir if it doesn't exist
	[ ! -d "$file_path" ] && mkdir "$file_path"

	# Make the auth file if it doesn't exist:
	[ ! -f "$file_path/authorized_keys" ] && touch "$file_path/authorized_keys"

	# Ensure correct perms
	chown -R "${sudo_user_name}":"${sudo_user_name}" "${file_path}"
	chmod 700 "${file_path}"
	chmod 600 "${file_path}/authorized_keys"

	# Add the key to the authorized_keys
	echo "${sudo_user_pubkey}" | tee --append "${file_path}/authorized_keys" > /dev/null

	# Logging
	log " Added pubkey to ${file_path}/authorized_keys: ${sudo_user_pubkey}"
fi



# ██╗  ██╗ █████╗ ██████╗ ██████╗ ███████╗███╗   ██╗    ███████╗███████╗██╗  ██╗
# ██║  ██║██╔══██╗██╔══██╗██╔══██╗██╔════╝████╗  ██║    ██╔════╝██╔════╝██║  ██║
# ███████║███████║██████╔╝██║  ██║█████╗  ██╔██╗ ██║    ███████╗███████╗███████║
# ██╔══██║██╔══██║██╔══██╗██║  ██║██╔══╝  ██║╚██╗██║    ╚════██║╚════██║██╔══██║
# ██║  ██║██║  ██║██║  ██║██████╔╝███████╗██║ ╚████║    ███████║███████║██║  ██║
# ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝    ╚══════╝╚══════╝╚═╝  ╚═╝
#
# Logging
log_prefix="|| harden-ssh |"

# Change the port used for SSH
if [ -n "$ssh_custom_port" ]; then
	log "SSH port changed to ${ssh_custom_port}"
	sed -i "s/#\?\(Port\s*\).*$/\1$ssh_custom_port/" /etc/ssh/sshd_config
fi

# Disable weak authentication
sed -i 's/#\?\(ChallengeResponseAuthentication\s*\).*$/\1no/' /etc/ssh/sshd_config
sed -i 's/#\?\(PasswordAuthentication\s*\).*$/\1no/' /etc/ssh/sshd_config

# Disable root logins
sed -i 's/#\?\(PermitRootLogin\s*\).*$/\1no/' /etc/ssh/sshd_config

# Enable PAM
sed -i 's/#\?\(UsePAM\s*\).*$/\1yes/' /etc/ssh/sshd_config

# Restart SSH Daemon
systemctl reload sshd

log "SSH Daemon restarted"



#  ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗ ██╗   ██╗██████╗ ███████╗    ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
# ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝ ██║   ██║██╔══██╗██╔════╝    ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
# ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗██║   ██║██████╔╝█████╗      ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ 
# ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║██║   ██║██╔══██╗██╔══╝      ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ 
# ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝╚██████╔╝██║  ██║███████╗    ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
#  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
#
# Logging   
log_prefix="|| hostname-setup |"

# Set correct hostname
hostnamectl set-hostname --static "${fqdn_hostname}"
log "hostname set to: ${fqdn_hostname}"

# Add self to DNS lookup servers (needed for virtualmin)
echo "prepend domain-name-servers 127.0.0.1;" | sudo tee -a /etc/dhcp/dhclient.conf > /dev/null
log "prepended self to dns in dhclient"

# Check for AWS cloud config file
CLOUD_CFG_FILE="/etc/cloud/cloud.cfg"
if test -f "$CLOUD_CFG_FILE"; then
	echo "preserve_hostname: true" | sudo tee -a "$CLOUD_CFG_FILE" > /dev/null
	log "AWS preserve_hostname set"
fi

# Retart the network
systemctl restart NetworkManager
log "NetworkManager service restarted"




# ██████╗ ███╗   ██╗███████╗    ██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗
# ██╔══██╗████╗  ██║██╔════╝    ██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
# ██║  ██║██╔██╗ ██║█████╗      ██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗  
# ██║  ██║██║╚██╗██║██╔══╝      ██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝  
# ██████╔╝██║ ╚████║██║         ╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗
# ╚═════╝ ╚═╝  ╚═══╝╚═╝          ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝
#
# Logging
log_prefix="|| dnf-update |"

# dnf update
log "Updating existing packages..."
dnf update -y -q
log "Finsihed updating"



# ██████╗ ███╗   ██╗███████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     
# ██╔══██╗████╗  ██║██╔════╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     
# ██║  ██║██╔██╗ ██║█████╗      ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     
# ██║  ██║██║╚██╗██║██╔══╝      ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     
# ██████╔╝██║ ╚████║██║         ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
# ╚═════╝ ╚═╝  ╚═══╝╚═╝         ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
#                
# Logging
log_prefix="|| dnf-install |"                                                           

# Add epel-release
log "Installing package: epel-release"
dnf install -y -q epel-release
log "Finished installing"

# Add other dependencies
PACKAGES=(
	tmux
	wget
	nano
	gcc
	gcc-c++
	gem
	git
	htop
	lm_sensors
	make
	ncdu
	perl
	perl-Authen-PAM
	perl-CPAN
	ruby-devel
	rubygems
	scl-utils
	util-linux
	zip
	unzip
)

log "Installing packages: ${PACKAGES[*]}"
dnf install -y -q "${PACKAGES[@]}"
log "Finished installing"



#  █████╗ ██████╗ ██████╗      █████╗ ██╗    ██╗███████╗       ██████╗██╗     ██╗
# ██╔══██╗██╔══██╗██╔══██╗    ██╔══██╗██║    ██║██╔════╝      ██╔════╝██║     ██║
# ███████║██║  ██║██║  ██║    ███████║██║ █╗ ██║███████╗█████╗██║     ██║     ██║
# ██╔══██║██║  ██║██║  ██║    ██╔══██║██║███╗██║╚════██║╚════╝██║     ██║     ██║
# ██║  ██║██████╔╝██████╔╝    ██║  ██║╚███╔███╔╝███████║      ╚██████╗███████╗██║
# ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚═╝  ╚═╝ ╚══╝╚══╝ ╚══════╝       ╚═════╝╚══════╝╚═╝
#                                                                                
# Logging
log_prefix="|| aws-cli |"

# Check we have AWS api credentials
if [[ -n "${aws_access_key}" && -n "${aws_secret_key}" ]]; then

	# Fetch and install AWS CLI v2
	if [ ! -f /usr/local/bin/aws ]; then
		curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
		unzip -o -q awscliv2.zip
		rm awscliv2.zip
		sudo ./aws/install
		rm -rf ./aws
		log "Installed aws-cli $(/usr/local/bin/aws --version)"
	else
		log "aws-cli is already installed"
	fi

    declare INSTANCE_REGION
    declare INSTANCE_ID
    declare INSTANCE_NAME
    declare aws_firewall_port_protocol

    #generate credntials file
	[ ! -d ~/.aws ] && mkdir ~/.aws # make dir if not exist
	if [ ! -f ~/.aws/credentials ]; then
		touch ~/.aws/credentials 
		echo "[default]" >> ~/.aws/credentials
		echo "aws_access_key_id=${aws_access_key}" >> ~/.aws/credentials
		echo "aws_secret_access_key=${aws_secret_key}" >> ~/.aws/credentials
	fi
    
    # get info on this instance
    INSTANCE_REGION=$(/usr/local/bin/aws configure list | grep region | awk '{print $2}')
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    INSTANCE_NAME=$(/usr/local/bin/aws lightsail get-instances --query "instances[?contains(supportCode,'`curl -s http://169.254.169.254/latest/meta-data/instance-id`')].name" --output text)
    log "Configured to control instance ${INSTANCE_NAME} ${INSTANCE_ID} running on ${INSTANCE_REGION}"

    # generate config file
	if [ ! -f ~/.aws/config ]; then
		touch ~/.aws/config         
        echo "[default]" >> ~/.aws/config
        echo "region=${INSTANCE_REGION}" >> ~/.aws/config
        echo "output=text" >> ~/.aws/config
    fi

    # Open Ports
	# aws_firewall_ports are declared at the top of the script
    log "Opening ports ${aws_firewall_ports[@]}"
    aws_firewall_port_protocol="tcp"

    for port in ${aws_firewall_ports[@]}; do
        # using "both" seems to cause a bug that removes all ports. fix this later.
        
        # if [ "$port" -gt "1000" ]; then
        #     aws_firewall_port_protocol="tcp"
        # else
        #     aws_firewall_port_protocol="both"
        # fi

        /usr/local/bin/aws lightsail open-instance-public-ports --cli-input-json "{
            \"portInfo\": {
                \"fromPort\": ${port},
                \"toPort\": ${port},
                \"protocol\": \"${aws_firewall_port_protocol}\"
            },
            \"instanceName\": \"${INSTANCE_NAME}\"
        }" | grep '"status": "Succeeded"' &> /dev/null

        if [ $? != 0 ]; then
            log "Failed to open port ${port}"
        fi
    done
else
    log "No AWS CLI credentials provided. Skipping aws-cli"
fi



#  █████╗ ██████╗ ██████╗     ███████╗██╗   ██╗███████╗██╗███╗   ██╗███████╗ ██████╗     ███╗   ███╗ ██████╗ ████████╗██████╗ 
# ██╔══██╗██╔══██╗██╔══██╗    ██╔════╝╚██╗ ██╔╝██╔════╝██║████╗  ██║██╔════╝██╔═══██╗    ████╗ ████║██╔═══██╗╚══██╔══╝██╔══██╗
# ███████║██║  ██║██║  ██║    ███████╗ ╚████╔╝ ███████╗██║██╔██╗ ██║█████╗  ██║   ██║    ██╔████╔██║██║   ██║   ██║   ██║  ██║
# ██╔══██║██║  ██║██║  ██║    ╚════██║  ╚██╔╝  ╚════██║██║██║╚██╗██║██╔══╝  ██║   ██║    ██║╚██╔╝██║██║   ██║   ██║   ██║  ██║
# ██║  ██║██████╔╝██████╔╝    ███████║   ██║   ███████║██║██║ ╚████║██║     ╚██████╔╝    ██║ ╚═╝ ██║╚██████╔╝   ██║   ██████╔╝
# ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚══════╝   ╚═╝   ╚══════╝╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝     ╚═╝     ╚═╝ ╚═════╝    ╚═╝   ╚═════╝ 
#   
# Logging                           
log_prefix="|| add-motd |"

sed -i 's/#\?\(PrintMotd\s*\).*$/\1no/' /etc/ssh/sshd_config
log "Updated sshd_config"

cp ./resources/motd.ls.sh /etc/profile.d/sysinfo.motd.sh
log "Installed and enabled SysInfo MotD"

chmod +x /etc/profile.d/sysinfo.motd.sh
log "SSH Daemon restarted"

systemctl restart sshd




# ██████╗ ██╗  ██╗██████╗     ███████╗██╗  ██╗
# ██╔══██╗██║  ██║██╔══██╗    ╚════██║██║  ██║
# ██████╔╝███████║██████╔╝        ██╔╝███████║
# ██╔═══╝ ██╔══██║██╔═══╝        ██╔╝ ╚════██║
# ██║     ██║  ██║██║            ██║██╗    ██║
# ╚═╝     ╚═╝  ╚═╝╚═╝            ╚═╝╚═╝    ╚═╝
#
# Logging
log_prefix="|| php-7.4 |"

dnf module enable php:7.4 -y -q
log "Enabled PHP7.4 Repo"

# Add other dependencies
PACKAGES=(
	php
	php-fpm
	php-bcmath
	php-cli
	php-common
	php-curl
	php-devel
	php-fpm
	php-gd
	php-gmp
	php-intl
	php-json
	php-mbstring
	php-mysqlnd
	php-opcache
	php-pdo
	php-pear
	php-pecl-apcu
	php-pecl-zip
	php-process
	php-simplexml
	php-soap
	php-xml
	php-xmlrpc
)

log "Installing packages: ${PACKAGES[*]}"
dnf install -y -q "${PACKAGES[@]}"

log "Finished installing"
log "Output from php -v: $( /usr/bin/php -v | head -n 1)"

# (Optional) Make this the default CLI version
#ln -s /usr/bin/php74 /usr/bin/php
#log "Created link in /usr/bin/php"



# ██████╗ ██╗  ██╗██████╗      █████╗    ██╗
# ██╔══██╗██║  ██║██╔══██╗    ██╔══██╗  ███║
# ██████╔╝███████║██████╔╝    ╚█████╔╝  ╚██║
# ██╔═══╝ ██╔══██║██╔═══╝     ██╔══██╗   ██║
# ██║     ██║  ██║██║         ╚█████╔╝██╗██║
# ╚═╝     ╚═╝  ╚═╝╚═╝          ╚════╝ ╚═╝╚═╝
#                                           
# Logging
log_prefix="|| php-8.1 |"

# Setup Remi repo
dnf config-manager --set-enabled powertools
dnf install -y -q https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install -y -q https://rpms.remirepo.net/enterprise/remi-release-8.rpm
log "Enabled PHP Remi 8.1 Repo"

# Configure packages to install
PACKAGES=(
	php81
	php81-php
	php81-php-fpm
	php81-php-bcmath
	php81-php-cli
	php81-php-common
	php81-php-curl
	php81-php-devel
	php81-php-fpm
	php81-php-gd
	php81-php-gmp
	php81-php-intl
	php81-php-json
	php81-php-mbstring
	php81-php-mcrypt
	php81-php-mysqlnd
	php81-php-opcache
	php81-php-pdo
	php81-php-pear
	php81-php-pecl-apcu
	php81-php-pecl-geoip
	php81-php-pecl-imagick
	php81-php-pecl-json-post
	php81-php-pecl-memcache
	php81-php-pecl-xmldiff
	php81-php-pecl-zip
	php81-php-process
	php81-php-pspell
	php81-php-simplexml
	php81-php-soap
	php81-php-tidy
	php81-php-xml
	php81-php-xmlrpc
)

log "Installing packages: ${PACKAGES[*]}"
dnf install -y -q "${PACKAGES[@]}"

log "Finished installing"
log "Output from php81 -v: $( /usr/bin/php81 -v | head -n 1)"

# (Optional) Make this the default CLI php version
#ln -s /usr/bin/php74 /usr/bin/php
#log "Created link in /usr/bin/php"



# ███╗   ███╗ █████╗ ██████╗ ██╗ █████╗ ██████╗ ██████╗      ██╗ ██████╗    ███████╗
# ████╗ ████║██╔══██╗██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗    ███║██╔═████╗   ██╔════╝
# ██╔████╔██║███████║██████╔╝██║███████║██║  ██║██████╔╝    ╚██║██║██╔██║   ███████╗
# ██║╚██╔╝██║██╔══██║██╔══██╗██║██╔══██║██║  ██║██╔══██╗     ██║████╔╝██║   ╚════██║
# ██║ ╚═╝ ██║██║  ██║██║  ██║██║██║  ██║██████╔╝██████╔╝     ██║╚██████╔╝██╗███████║
# ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═════╝ ╚═════╝      ╚═╝ ╚═════╝ ╚═╝╚══════╝
#             
# Logging
log_prefix="|| mariadb-10.5 |"                                                                      

# Install MariaDB 10.5
dnf module enable -y -q mariadb:10.5
dnf install -y -q mariadb

log "Upgraded MariaDB to $(mariadb -V)"
log "MariaDB service restarted "



#  █████╗ ██████╗ ██████╗     ███╗   ██╗ ██████╗ ██████╗ ███████╗     ██╗ █████╗    ██╗  ██╗
# ██╔══██╗██╔══██╗██╔══██╗    ████╗  ██║██╔═══██╗██╔══██╗██╔════╝    ███║██╔══██╗   ╚██╗██╔╝
# ███████║██║  ██║██║  ██║    ██╔██╗ ██║██║   ██║██║  ██║█████╗      ╚██║╚█████╔╝    ╚███╔╝ 
# ██╔══██║██║  ██║██║  ██║    ██║╚██╗██║██║   ██║██║  ██║██╔══╝       ██║██╔══██╗    ██╔██╗ 
# ██║  ██║██████╔╝██████╔╝    ██║ ╚████║╚██████╔╝██████╔╝███████╗     ██║╚█████╔╝██╗██╔╝ ██╗
# ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝     ╚═╝ ╚════╝ ╚═╝╚═╝  ╚═╝
#
# Logging
log_prefix="|| node-js |"

# Install NodeJS v18.x
dnf module enable -y -q nodejs:18
log "Enabled NodeJS v18.x, installing"

dnf install -y -q nodejs
log "Installed NodeJS $(node -v)"

# Update npm via self
log "Updating NPM via self"
npm install -g --quiet npm@latest
log "Installed NPM $(npm -v)"



#  █████╗ ██████╗ ██████╗     ███╗   ██╗██████╗ ███╗   ███╗    ██████╗  █████╗  ██████╗██╗  ██╗ █████╗  ██████╗ ███████╗███████╗
# ██╔══██╗██╔══██╗██╔══██╗    ████╗  ██║██╔══██╗████╗ ████║    ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔════╝ ██╔════╝██╔════╝
# ███████║██║  ██║██║  ██║    ██╔██╗ ██║██████╔╝██╔████╔██║    ██████╔╝███████║██║     █████╔╝ ███████║██║  ███╗█████╗  ███████╗
# ██╔══██║██║  ██║██║  ██║    ██║╚██╗██║██╔═══╝ ██║╚██╔╝██║    ██╔═══╝ ██╔══██║██║     ██╔═██╗ ██╔══██║██║   ██║██╔══╝  ╚════██║
# ██║  ██║██████╔╝██████╔╝    ██║ ╚████║██║     ██║ ╚═╝ ██║    ██║     ██║  ██║╚██████╗██║  ██╗██║  ██║╚██████╔╝███████╗███████║
# ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚═╝  ╚═══╝╚═╝     ╚═╝     ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝
#                                                                                                                               
# Logging
log_prefix="|| npm-install |"

# Install LESS and SASS preprocessors
log "Installing LESS and SASS"
npm install -g --quiet less sass

log "Installed less $(/usr/local/bin/lessc --version)"
log "Installed sass $(/usr/local/bin/sass --version)"



# ██╗   ██╗██╗██████╗ ████████╗██╗   ██╗ █████╗ ██╗     ███╗   ███╗██╗███╗   ██╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     
# ██║   ██║██║██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██║     ████╗ ████║██║████╗  ██║    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     
# ██║   ██║██║██████╔╝   ██║   ██║   ██║███████║██║     ██╔████╔██║██║██╔██╗ ██║    ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     
# ╚██╗ ██╔╝██║██╔══██╗   ██║   ██║   ██║██╔══██║██║     ██║╚██╔╝██║██║██║╚██╗██║    ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     
#  ╚████╔╝ ██║██║  ██║   ██║   ╚██████╔╝██║  ██║███████╗██║ ╚═╝ ██║██║██║ ╚████║    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
#   ╚═══╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
## Logging
log_prefix="|| virtualmin-installer |"

# Get the installer
curl -o ./virtualmin-installer.sh http://software.virtualmin.com/gpl/scripts/install.sh
chmod +x ./virtualmin-installer.sh
log "got latest installer"

# Run the installer
log "triggering install with hostname ${fqdn_hostname}"
./virtualmin-installer.sh --hostname "${fqdn_hostname}" --force
log "finished install with hostname ${fqdn_hostname}"


# Update the password
if [[ -n "${virtualmin_user}" && -n "${virtualmin_password}" ]]; then
	sudo /usr/libexec/webmin/changepass.pl /etc/webmin $virtualmin_user $virtualmin_password
	log "password updated for Virtualmin user ${virtualmin_user}"
fi



# ██╗   ██╗██╗██████╗ ████████╗██╗   ██╗ █████╗ ██╗     ███╗   ███╗██╗███╗   ██╗    ██████╗  ██████╗ ███████╗████████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     
# ██║   ██║██║██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██║     ████╗ ████║██║████╗  ██║    ██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     
# ██║   ██║██║██████╔╝   ██║   ██║   ██║███████║██║     ██╔████╔██║██║██╔██╗ ██║    ██████╔╝██║   ██║███████╗   ██║       ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     
# ╚██╗ ██╔╝██║██╔══██╗   ██║   ██║   ██║██╔══██║██║     ██║╚██╔╝██║██║██║╚██╗██║    ██╔═══╝ ██║   ██║╚════██║   ██║       ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     
#  ╚████╔╝ ██║██║  ██║   ██║   ╚██████╔╝██║  ██║███████╗██║ ╚═╝ ██║██║██║ ╚████║    ██║     ╚██████╔╝███████║   ██║       ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
#   ╚═══╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝    ╚═╝      ╚═════╝ ╚══════╝   ╚═╝       ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
#
# Logging
log_prefix="|| virtualmin-post-install |"

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
# This needs to be done BEFORE you upgrade to MariaDB 10.5+ due to the bug described at https://www.virtualmin.com/node/64694
if [ -n "${mysql_root_password}" ]; then
	output=$(virtualmin set-mysql-pass --user root --pass "${mysql_root_password}")
	log "Updated root password for MySQL: $output"
fi

# Set MySQL server memory size
sed_param=s/mysql_size=.*/mysql_size=${MYSQL_MEMORY}/  
sed -i "$sed_param" $CONFIG
log "MySQL memory setting is ${MYSQL_MEMORY}"


# Enable preloading of virtualmin libraries
sed -i 's/preload_mode=.*/preload_mode=1/' $CONFIG
log "Enabled Virtualmin library preloading"

# Enable ClamAV server
sed -i 's/virus=.*/virus=1/' $CONFIG
log "Enabled ClamAV server"

# Enable SpamAssassin server
sed -i 's/spam=.*/spam=1/' $CONFIG
log "Enabled SpamAssassin server"

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
#		$v .=" rootflags=uquota,gquota";
#		}
#

# Update the config file to let it know quotas are enabled
#sed -i 's/quotas=.*/quotas=1/' $CONFIG

log "Enabled quotas" 

# Enable hashed passwords
sed -i 's/hashpass=.*/hashpass=1/' $CONFIG
log "Enabled hashed passwords"

# Enable wizard_run flag
echo "wizard_run=1" >> $CONFIG
sed -i 's/wizard_run=.*/wizard_run=1/' $CONFIG
log "Manually added wizard_run flag"

# Redirect non-SSL calls to the admin panel to SSL
sed -i 's/ssl_redirect=.*/ssl_redirect=1/' /etc/webmin/miniserv.conf
log "Enabled non-SSL to SSL redirect for Webmin panel"

# Enable SSL by default
output=$(virtualmin set-global-feature --default-on ssl)
log "SSL enabled: $output"

# Disable AWstats by default
output=$(virtualmin set-global-feature --default-off virtualmin-awstats )
log "Virtualmin AWStats disabled: $output"

# Disable DAV by default
output=$(virtualmin set-global-feature --default-off virtualmin-dav )
log "Virtualmin DAV disabled: $output"

# Change autoconfig script to have hard-coded STARTTLS
output=$(virtualmin modify-mail --all-domains --autoconfig)
log "Virtualmin Enable auto-config: $output"

output=$(virtualmin modify-template --id 0 --setting autoconfig --value "$(cat ./resources/autoconfig.xml | tr '\n' ' ')")
log "Virtualmin Update autoconfig.xml: $output"
log "Virtualmin autoconfig enabled and STARTTLS hard-coded"

output=$(virtualmin modify-template --id 0 --setting autodiscover --value "$(cat ./resources/autodiscover.xml | tr '\n' ' ')")
log "Virtualmin Update autodiscover.xml: $output"


# fin
log "Virtualmin Post-Install Wizard setup complete"



# ██████╗ ███████╗███████╗ █████╗ ██╗   ██╗██╗  ████████╗    ██████╗  ██████╗ ███╗   ███╗ █████╗ ██╗███╗   ██╗
# ██╔══██╗██╔════╝██╔════╝██╔══██╗██║   ██║██║  ╚══██╔══╝    ██╔══██╗██╔═══██╗████╗ ████║██╔══██╗██║████╗  ██║
# ██║  ██║█████╗  █████╗  ███████║██║   ██║██║     ██║       ██║  ██║██║   ██║██╔████╔██║███████║██║██╔██╗ ██║
# ██║  ██║██╔══╝  ██╔══╝  ██╔══██║██║   ██║██║     ██║       ██║  ██║██║   ██║██║╚██╔╝██║██╔══██║██║██║╚██╗██║
# ██████╔╝███████╗██║     ██║  ██║╚██████╔╝███████╗██║       ██████╔╝╚██████╔╝██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
# ╚═════╝ ╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝       ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
#
# Logging
log_prefix="|| create-default-domain |"

# Generate a random password for the default domain user account
webmin_password=$(date +%s|sha256sum|sha256sum|base64|head -c 32)

# Create a virtual site for the default domain
output=$(virtualmin create-domain --domain "${fqdn_hostname}" --pass "${webmin_password}" --default-features)
log "$output"

declare HOME_DIR=$(virtualmin list-domains | grep "${fqdn_hostname}" | awk -F" " '{print $2}')

if [ -n "$HOME_DIR" ]; then
	# Copy default server status page
	cp ./resources/index.html "/home/${HOME_DIR}/public_html/index.html"
	log "Created /home/${HOME_DIR}/public_html/index.html"
	
	# Update status page with correct domain
	sed -i -e "s/example\.com/${fqdn_hostname}/g" "/home/${HOME_DIR}/public_html/index.html"
fi

# Generate and install lets encrypt certificate
output=$(virtualmin generate-letsencrypt-cert --domain "$1")
log "$output"

output=$(virtualmin install-service-cert --domain "$1" --service postfix)
log "$output"
output=$(virtualmin install-service-cert --domain "$1" --service usermin)
log "$output"
output=$(virtualmin install-service-cert --domain "$1" --service webmin)
log "$output"
output=$(virtualmin install-service-cert --domain "$1" --service dovecot)
log "$output"
output=$(virtualmin install-service-cert --domain "$1" --service proftpd)
log "$output"

log "LetsEncrypt certificate requested and copied to services (see RALVIN.ssl.log for more info)"



# ██████╗ ██╗  ██╗██████╗     ██╗███╗   ██╗██╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗
# ██╔══██╗██║  ██║██╔══██╗    ██║████╗  ██║██║    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝
# ██████╔╝███████║██████╔╝    ██║██╔██╗ ██║██║       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ ███████╗
# ██╔═══╝ ██╔══██║██╔═══╝     ██║██║╚██╗██║██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ╚════██║
# ██║     ██║  ██║██║         ██║██║ ╚████║██║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████║
# ╚═╝     ╚═╝  ╚═╝╚═╝         ╚═╝╚═╝  ╚═══╝╚═╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#
# Logging
log_prefix="|| php-ini-tweaks |"

# Add PHP 8.1 php.ini to webmin
echo "/etc/opt/remi/php81/php.ini" | sudo tee -a /etc/webmin/phpini/config > /dev/null
echo $(sudo head -c -1 /etc/webmin/phpini/config) | sudo tee /etc/webmin/phpini/config > /dev/null
log "Added PHP 8.1 php.ini to Webmin"

# Tweaks various settings for php.ini
output=$(virtualmin modify-php-ini --all-domains --ini-name upload_max_filesize --ini-value 32M)
log "Setting upload_max_filesize to 32M: $output"

output=$(virtualmin modify-php-ini --all-domains --ini-name post_max_size  --ini-value 32M)
log "Setting post_max_size to 32M: $output"

# Add GNU Terry Pratchett 
tee -a /etc/httpd/conf/httpd.conf > /dev/null <<EOT

#  ╔═╗╔╗╔╦ ╦  ╔╦╗┌─┐┬─┐┬─┐┬ ┬  ╔═╗┬─┐┌─┐┌┬┐┌─┐┬ ┬┌─┐┌┬┐┌┬┐
#  ║ ╦║║║║ ║   ║ ├┤ ├┬┘├┬┘└┬┘  ╠═╝├┬┘├─┤ │ │  ├─┤├┤  │  │ 
#  ╚═╝╝╚╝╚═╝   ╩ └─┘┴└─┴└─ ┴   ╩  ┴└─┴ ┴ ┴ └─┘┴ ┴└─┘ ┴  ┴ 
<IfModule headers_module>
  header set X-Clacks-Overhead "GNU Terry Pratchett"
</IfModule>
EOT

log "Added GNU Terry Pratchett to httpd.conf"

# Restart apache
systemctl restart httpd
log "Restarted httpd service"



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
log_prefix="|| enable-2fa |"

# Copy the CPAN config file
log "Installing cpanminus"
dnf install -q -y cpanminus

# Install the right modules
PACKAGES=(
	Archive::Tar
	Authen::OATH
	Digest::HMAC
	Digest::SHA
	Math::BigInt
	Moo
	Moose
	Module::Build
	Test::More
	Test::Needs
	Type::Tiny
	Types::Standard
)

log "Installing perl packages: ${PACKAGES[*]}"
cpanm install -q "${PACKAGES[@]}"
log "Install finished"

# Enable Google Authenticator
echo "twofactor_provider=totp" | sudo tee -a /etc/webmin/miniserv.conf > /dev/null
log "Enabled Google Authenticator 2FA for Webmin. You will need to enroll a user manually."



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
log_prefix="|| harden-postfix |"

# Backup the current/default config
postconf | sudo tee /root/postfix.main.cf.$(date "+%F-%T") > /dev/null
log "Backed up original config to /root/postfix.main.cf.$(date "+%F-%T")"

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
output=$(postfix reload > /dev/null)
log "Reloading postfix: $output"

systemctl restart postfix
log "Postfix hardened and restarted"


printf "\n"
printf "|| RALVIN has completed \n"
printf "|| ========================================================\n"
printf "|| FQDN hostname:                  ${fqdn_hostname} \n"
printf "|| SSH port:                       ${ssh_custom_port} \n"
printf "|| Sudo user:                      ${sudo_user_name} \n"
printf "|| Sudo password:                  ${sudo_user_password} \n"
printf "|| Sudo user pubkey:               ${sudo_user_pubkey} \n"
printf "|| MySQL root password:            ${mysql_root_password} \n"
printf "|| Virtualmin user:                ${virtualmin_user} \n"
printf "|| Virtualmin password:            ${virtualmin_password} \n"
printf "|| Virtualmin panel:               https://${fqdn_hostname}:10000 \n"

if [ -n "$aws_access_key" ]; then
	printf "|| AWS Access key:                 ${aws_access_key} \n"
fi
if [ -n "$aws_secret_key" ]; then
	printf "|| AWS Secret key:                 ${aws_secret_key} \n"
fi