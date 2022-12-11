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
declare -l fqdn_hostname
declare sudo_user_pubkey
declare sudo_user_name
declare sudo_user_password
declare virtualmin_user_name
declare virtualmin_password
declare myqsl_root_password
declare aws_access_key
declare aws_secret_key

declare -a aws_firewall_ports=(22 25 80 443 465 587 993 10000 20000)



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
			echo "  -suk, --sudo-user-pubkey [valid pubkey]     specify an public key to be added to the authorized_keys file for the sudo user"
			echo "  -suu, --sudo-user-name [root]                   specify a user account to use (or create) as the sudo account"
			echo "  -sup, --sudo-user-password [mypassword]         specify a password for the sudo account"
			echo "  -vu, --virtualmin-user [root]             specify a user to enable the Vitualmin admin panel password for"
			echo "  -vp, --virtualmin-password [mypassword]   specify a password to use for the Virtualmin admin panel"
			echo "  -mp, --mysql-password [mypassword]        specify a password to use for the MySQL root user"
			echo "  -a, --aws-access-key [key]                optional: aws access key to use for aws-cli"
			echo "  -s, --aws-secret-key [key]                optional: aws secret key to use for aws-cli"
			echo "  -ss, --ssh-port [number]                  optional: a custom port to use for the ssh server"
			exit 0
			;;
		-d|--domain)
			fqdn_hostname="$2"
			shift 2
			;;
			
		-suu|--sudo-user-name)
			sudo_user_name="$2"
			shift 2
			;;
		-suk|--sudo-user-pubkey)
			sudo_user_pubkey="$2"
			shift 2
			;;
		-sup|--sudo-password)
			sudo_user_password="$2"
			shift 2
			;;

		-vu|--virtualmin-user-name)
			virtualmin_user_name="$2"
			shift 2
			;;
		-vp|--virtualmin-password)
			virtualmin_password="$2"
			shift 2
			;;

		-mp|--mysql-password)
			myqsl_root_password="$2"
			shift 2
			;;

		-a|--aws-access-key)
			aws_access_key="$2"
			shift 2
			;;
		-s|--aws-secret-key)
			aws_secret_key="$2"
			shift 2
			;;

		-ss|--ssh-port)
			ssh_custom_port="$2"
			shift 2
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
if [ -z "$fqdn_hostname" ]; then
	read -e -p "|| Enter a valid FQDN: " -i "example.com" fqdn_hostname
fi

# Quit out if the user failed to provide a FQDN
if [ -z "$fqdn_hostname" ]; then
	printf "|| You must specify a FQDN. Script is exiting.\n\n"
	exit 0
fi

# Check if we're using a pubkey, or request one
if [ -z "$sudo_user_pubkey" ]; then
	read -e -p "|| Enter an optional public key to install: " -i "${sudo_user_pubkey}" PUBKEY
fi

# Check we have a sudo user account name to create
if [ -z "$sudo_user_name" ]; then
	sudo_user_name="rocky"
	read -e -p "|| Enter a name for the sudo user account: " -i "${sudo_user_name}" sudo_user_name
fi

# Check we have a password to use for the Virtualmin admin
if [ -z "$sudo_user_password" ]; then
	sudo_user_password=$(date +%s|sha256sum|base64|head -c 32)
	read -e -p "|| Enter a password for the sudo user account: " -i "${sudo_user_password}" sudo_user_password
fi

# Check we have a user to set the password for
if [ -z "$virtualmin_user_name" ]; then
	read -e -p "|| Enter a valid user to grant access to the Virtualmin admin panel: " -i "root" virtualmin_user_name
fi

# Check we have a password to use for the Virtualmin admin
if [ -z "$virtualmin_password" ]; then
	virtualmin_password=$(date +%s|sha256sum|base64|head -c 32)
	read -e -p "|| Enter a password for the Virtualmin admin panel: " -i "${virtualmin_password}" virtualmin_password
fi

# Check we have a password to set for the MySQL root user
if [ -z "$myqsl_root_password" ]; then
	myqsl_root_password=$(date +%s|sha256sum|sha256sum|base64|head -c 32)
	read -e -p "|| Enter a password for the MySQL root user: " -i "${myqsl_root_password}" myqsl_root_password
fi

# AWS Credentials
# Check for an AWS access key
if [ -z "$aws_access_key" ]; then
	read -e -p "|| Enter an (optional) aws-cli ACCESS KEY: " -i "${aws_access_key}" aws_access_key
fi

# Check for an AWS secret key
if [ -z "$aws_secret_key" ]; then
	read -e -p "|| Enter an (optional) aws-cli SECRET KEY: " -i "${aws_secret_key}" aws_secret_key
fi

# Check for a a custom SSH port
if [ -z "$ssh_custom_port" ]; then
	read -e -p "|| Enter an (optional) custom SSH port: " -i "${ssh_custom_port}" ssh_custom_port
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
log_prefix="RALVIN | create-sudo-user |"

if [ ! -z "${sudo_user_name}" || ! -z "${sudo_user_password}"]; then

	# Check if the user account already exists
	if id "${sudo_user_name}" &>/dev/null; then
		echo "${log_prefix} User already exists" >> ./RALVIN.log
	else
		# Add the user account, and set the password
		useradd ${sudo_user_name}
		echo "${log_prefix} Created user: ${sudo_user_name}" >> ./RALVIN.log

		echo "${sudo_user_password}" | passwd "${sudo_user_name}" --stdin
		echo "${log_prefix} Updated password for user: ${sudo_user_name}" >> ./RALVIN.log
	fi

	# Add the uset to the wheel group
	usermod -aG wheel ${sudo_user_name}
	echo "${log_prefix} Added user ${sudo_user_name} to wheel group" >> ./RALVIN.log

	# Optional: disable password entry for sudo use:
	#echo "${sudo_user_name} ALL=(ALL) NOPASSWD: ALL" | sudo tee --append /etc/sudoers
else
	echo "${log_prefix} Can't create sudo user, missing username or password" >> ./RALVIN.log
fi



#  █████╗ ██████╗ ██████╗     ██████╗ ██╗   ██╗██████╗ ██╗  ██╗███████╗██╗   ██╗
# ██╔══██╗██╔══██╗██╔══██╗    ██╔══██╗██║   ██║██╔══██╗██║ ██╔╝██╔════╝╚██╗ ██╔╝
# ███████║██║  ██║██║  ██║    ██████╔╝██║   ██║██████╔╝█████╔╝ █████╗   ╚████╔╝ 
# ██╔══██║██║  ██║██║  ██║    ██╔═══╝ ██║   ██║██╔══██╗██╔═██╗ ██╔══╝    ╚██╔╝  
# ██║  ██║██████╔╝██████╔╝    ██║     ╚██████╔╝██████╔╝██║  ██╗███████╗   ██║   
# ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚═╝      ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝   ╚═╝   
#
# Logging
log_prefix="RALVIN | add-public-key |"

if [ -z "${sudo_user_pubkey}" || -z "${sudo_user_name}" ]; then
	echo "${log_prefix} Skipping pubkey (none provided)" >> ./RALVIN.log
else
	file_path= "/home/${sudo_user_name}/.ssh"

	mkdir "${file_path}"
	chmod 700 "${file_path}"
	touch "${file_path}/authorized_keys"
	chmod 600 "${file_path}/authorized_keys"
	echo "${sudo_user_pubkey}" | tee --append "${file_path}/authorized_keys"
	chown -R ${sudo_user_name}:${sudo_user_name} "${file_path}"

	echo "${log_prefix}  Added pubkey to ${file_path}/authorized_keys: ${sudo_user_pubkey}" >> ./RALVIN.log
fi



# ██╗  ██╗ █████╗ ██████╗ ██████╗ ███████╗███╗   ██╗    ███████╗███████╗██╗  ██╗
# ██║  ██║██╔══██╗██╔══██╗██╔══██╗██╔════╝████╗  ██║    ██╔════╝██╔════╝██║  ██║
# ███████║███████║██████╔╝██║  ██║█████╗  ██╔██╗ ██║    ███████╗███████╗███████║
# ██╔══██║██╔══██║██╔══██╗██║  ██║██╔══╝  ██║╚██╗██║    ╚════██║╚════██║██╔══██║
# ██║  ██║██║  ██║██║  ██║██████╔╝███████╗██║ ╚████║    ███████║███████║██║  ██║
# ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝    ╚══════╝╚══════╝╚═╝  ╚═╝
#
# Logging
log_prefix="RALVIN | harden-ssh |"

# Change the port used for SSH
if [ ! -z "$ssh_custom_port" ]; then
	echo "${log_prefix} SSH port changed to ${ssh_custom_port}" >> ./RALVIN.log
	sed -i 's/#\?\(Port\s*\).*$/\1 ${ssh_custom_port}/' /etc/ssh/sshd_config
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

echo "${log_prefix} SSH Daemon restarted" >> ./RALVIN.log



#  ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗ ██╗   ██╗██████╗ ███████╗    ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
# ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝ ██║   ██║██╔══██╗██╔════╝    ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
# ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗██║   ██║██████╔╝█████╗      ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ 
# ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║██║   ██║██╔══██╗██╔══╝      ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ 
# ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝╚██████╔╝██║  ██║███████╗    ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
#  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
#
# Logging   
log_prefix="RALVIN | hostname-setup |"

# Set correct hostname
hostnamectl set-hostname --static "${fqdn_hostname}"
echo "${log_prefix} hostname set to: ${fqdn_hostname}" >> ./RALVIN.log

# Add self to DNS lookup servers (needed for virtualmin)
echo "prepend domain-name-servers 127.0.0.1;" | sudo tee -a /etc/dhcp/dhclient.conf

# Check for AWS cloud config file
CLOUD_CFG_FILE="/etc/cloud/cloud.cfg"
if test -f "$CLOUD_CFG_FILE"; then
	echo "preserve_hostname: true" | sudo tee -a "$CLOUD_CFG_FILE"
	echo "${log_prefix} AWS preserve_hostname set" >> ./RALVIN.log
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
log_prefix="RALVIN | dnf-update |"

# dnf update
dnf update -y
echo "${log_prefix} Updated existing packages" >> ./RALVIN.log



# ██████╗ ███╗   ██╗███████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     
# ██╔══██╗████╗  ██║██╔════╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     
# ██║  ██║██╔██╗ ██║█████╗      ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     
# ██║  ██║██║╚██╗██║██╔══╝      ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     
# ██████╔╝██║ ╚████║██║         ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
# ╚═════╝ ╚═╝  ╚═══╝╚═╝         ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
#                
# Logging
log_prefix="RALVIN | dnf-install |"                                                           

# Add epel-release
dnf install -y epel-release
echo "${log_prefix} Installed package: epel-release" >> ./RALVIN.log

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

dnf install -y "${PACKAGES[@]}" &&
echo "${log_prefix} Installed packages:" >> ./RALVIN.log
echo "${log_prefix} ${PACKAGES[@]}" >> ./RALVIN.log



#  █████╗ ██████╗ ██████╗      █████╗ ██╗    ██╗███████╗       ██████╗██╗     ██╗
# ██╔══██╗██╔══██╗██╔══██╗    ██╔══██╗██║    ██║██╔════╝      ██╔════╝██║     ██║
# ███████║██║  ██║██║  ██║    ███████║██║ █╗ ██║███████╗█████╗██║     ██║     ██║
# ██╔══██║██║  ██║██║  ██║    ██╔══██║██║███╗██║╚════██║╚════╝██║     ██║     ██║
# ██║  ██║██████╔╝██████╔╝    ██║  ██║╚███╔███╔╝███████║      ╚██████╗███████╗██║
# ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚═╝  ╚═╝ ╚══╝╚══╝ ╚══════╝       ╚═════╝╚══════╝╚═╝
#                                                                                
# Logging
log_prefix="RALVIN | aws-cli |"

# Fetch and install AWS CLI v2
if [ ! -f /usr/local/bin/aws ]; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -o -q awscliv2.zip
    rm awscliv2.zip
    sudo ./aws/install
    rm -rf ./aws
    echo "${log_prefix} Installed aws-cli $(/usr/local/bin/aws --version)" >> ./RALVIN.log
fi

# add aws-cli credentials if provided
if [[ ! -z "${aws_access_key}" && ! -z "${aws_secret_key}" ]]; then
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
    echo "${log_prefix} Configured to control instance ${INSTANCE_NAME} ${INSTANCE_ID} running on ${INSTANCE_REGION}" >> ./RALVIN.log

    # generate config file
	if [ ! -f ~/.aws/config ]; then
		touch ~/.aws/config         
        echo "[default]" >> ~/.aws/config
        echo "region=${INSTANCE_REGION}" >> ~/.aws/config
        echo "output=text" >> ~/.aws/config
    fi

    # Open Ports
	# aws_firewall_ports are declared at the top of the script
    echo "${log_prefix} Opening ports ${aws_firewall_ports[@]}" >> ./RALVIN.log
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
            echo "${log_prefix} Failed to open port ${port}" >> ./RALVIN.log
        fi
    done
else
    echo "${log_prefix} No AWS CLI credentials provided. Unable to configure ports" >> ./RALVIN.log
fi



#  █████╗ ██████╗ ██████╗     ███████╗██╗   ██╗███████╗██╗███╗   ██╗███████╗ ██████╗     ███╗   ███╗ ██████╗ ████████╗██████╗ 
# ██╔══██╗██╔══██╗██╔══██╗    ██╔════╝╚██╗ ██╔╝██╔════╝██║████╗  ██║██╔════╝██╔═══██╗    ████╗ ████║██╔═══██╗╚══██╔══╝██╔══██╗
# ███████║██║  ██║██║  ██║    ███████╗ ╚████╔╝ ███████╗██║██╔██╗ ██║█████╗  ██║   ██║    ██╔████╔██║██║   ██║   ██║   ██║  ██║
# ██╔══██║██║  ██║██║  ██║    ╚════██║  ╚██╔╝  ╚════██║██║██║╚██╗██║██╔══╝  ██║   ██║    ██║╚██╔╝██║██║   ██║   ██║   ██║  ██║
# ██║  ██║██████╔╝██████╔╝    ███████║   ██║   ███████║██║██║ ╚████║██║     ╚██████╔╝    ██║ ╚═╝ ██║╚██████╔╝   ██║   ██████╔╝
# ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚══════╝   ╚═╝   ╚══════╝╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝     ╚═╝     ╚═╝ ╚═════╝    ╚═╝   ╚═════╝ 
#   
# Logging                           
log_prefix="RALVIN | add-motd |"

sed -i 's/#\?\(PrintMotd\s*\).*$/\1 no/' /etc/ssh/sshd_config
echo "${log_prefix} Updated sshd_config" >> ./RALVIN.log

cp ./resources/motd.ls.sh /etc/profile.d/sysinfo.motd.sh
echo "${log_prefix} Installed and enabled SysInfo MotD" >> ./RALVIN.log

chmod +x /etc/profile.d/sysinfo.motd.sh
echo "${log_prefix} SSH Daemon restarted" >> ./RALVIN.log

systemctl restart sshd




# ██████╗ ██╗  ██╗██████╗     ███████╗██╗  ██╗
# ██╔══██╗██║  ██║██╔══██╗    ╚════██║██║  ██║
# ██████╔╝███████║██████╔╝        ██╔╝███████║
# ██╔═══╝ ██╔══██║██╔═══╝        ██╔╝ ╚════██║
# ██║     ██║  ██║██║            ██║██╗    ██║
# ╚═╝     ╚═╝  ╚═╝╚═╝            ╚═╝╚═╝    ╚═╝
#
# Logging
log_prefix="RALVIN | php-7.4 |"

dnf module enable php:7.4 -y
echo "${log_prefix} Enabled PHP7.4 Repo" >> ./RALVIN.log

PACKAGES=""
PACKAGES="${PACKAGES} php php-fpm php-bcmath php-cli php-common php-curl php-devel"
PACKAGES="${PACKAGES} php-fpm php-gd php-gmp php-intl php-json php-mbstring php-mysqlnd"
PACKAGES="${PACKAGES} php-opcache php-pdo php-pear php-pecl-apcu php-pecl-zip php-process"
PACKAGES="${PACKAGES} php-simplexml php-soap php-xml php-xmlrpc"

dnf install -y $PACKAGES

echo "${log_prefix} Installed PHP 7.4: $( /usr/bin/php -v | head -n 1)" >> ./RALVIN.log
echo "${log_prefix} Installed packages: ${PACKAGES}" >> ./RALVIN.log

# (Optional) Make this the default CLI version
#ln -s /usr/bin/php74 /usr/bin/php
#echo "${log_prefix} Created link in /usr/bin/php" >> ./RALVIN.log



# ██████╗ ██╗  ██╗██████╗      █████╗    ██╗
# ██╔══██╗██║  ██║██╔══██╗    ██╔══██╗  ███║
# ██████╔╝███████║██████╔╝    ╚█████╔╝  ╚██║
# ██╔═══╝ ██╔══██║██╔═══╝     ██╔══██╗   ██║
# ██║     ██║  ██║██║         ╚█████╔╝██╗██║
# ╚═╝     ╚═╝  ╚═╝╚═╝          ╚════╝ ╚═╝╚═╝
#                                           
# Logging
log_prefix="RALVIN | php-8.1 |"

# Setup Remi repo
dnf config-manager --set-enabled powertools
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
echo "${log_prefix} Enabled PHP Remi 8.1 Repo" >> ./RALVIN.log

# Configure packages to install
PACKAGES=""
PACKAGES="${PACKAGES} php81 php81-php php81-php-fpm php81-php-bcmath php81-php-cli php81-php-common"
PACKAGES="${PACKAGES} php81-php-curl php81-php-devel php81-php-fpm php81-php-gd php81-php-gmp php81-php-intl php81-php-json"
PACKAGES="${PACKAGES} php81-php-mbstring php81-php-mcrypt php81-php-mysqlnd php81-php-opcache php81-php-pdo php81-php-pear"
PACKAGES="${PACKAGES} php81-php-pecl-apcu php81-php-pecl-geoip php81-php-pecl-imagick php81-php-pecl-json-post"
PACKAGES="${PACKAGES} php81-php-pecl-memcache php81-php-pecl-xmldiff php81-php-pecl-zip php81-php-process php81-php-pspell"
PACKAGES="${PACKAGES} php81-php-simplexml php81-php-soap php81-php-tidy php81-php-xml php81-php-xmlrpc"

dnf install -y $PACKAGES

echo "${log_prefix} Installed Remi PHP 8.1: $( /usr/bin/php81 -v | head -n 1)" >> ./RALVIN.log
echo "${log_prefix} Installed packages: ${PACKAGES}" >> ./RALVIN.log

# (Optional) Make this the default CLI php version
#ln -s /usr/bin/php74 /usr/bin/php
#echo "${log_prefix} Created link in /usr/bin/php" >> ./RALVIN.log



# ███╗   ███╗ █████╗ ██████╗ ██╗ █████╗ ██████╗ ██████╗      ██╗ ██████╗    ███████╗
# ████╗ ████║██╔══██╗██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗    ███║██╔═████╗   ██╔════╝
# ██╔████╔██║███████║██████╔╝██║███████║██║  ██║██████╔╝    ╚██║██║██╔██║   ███████╗
# ██║╚██╔╝██║██╔══██║██╔══██╗██║██╔══██║██║  ██║██╔══██╗     ██║████╔╝██║   ╚════██║
# ██║ ╚═╝ ██║██║  ██║██║  ██║██║██║  ██║██████╔╝██████╔╝     ██║╚██████╔╝██╗███████║
# ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═════╝ ╚═════╝      ╚═╝ ╚═════╝ ╚═╝╚══════╝
#             
# Logging
log_prefix="RALVIN | mariadb-10.5 |"                                                                      

# Install MariaDB 10.5
dnf module enable -y mariadb:10.5
dnf install -y mariadb

echo "${log_prefix} Upgraded MariaDB to $(mariadb -V)" >> ./RALVIN.log
echo "${log_prefix} MariaDB service restarted " >> ./RALVIN.log



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

# Update npm via self
npm install -g npm@latest

# Logging
log_prefix="RALVIN | node-js |"
echo "${log_prefix} Installed NodeJS $(node -v)" >> ./RALVIN.log
echo "${log_prefix} Installed NPM $(npm -v)" >> ./RALVIN.log



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
log_prefix="RALVIN | npm-install |"
echo "${log_prefix} LESS and SASS installed via NPM" >> ./RALVIN.log



# ██╗   ██╗██╗██████╗ ████████╗██╗   ██╗ █████╗ ██╗     ███╗   ███╗██╗███╗   ██╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     
# ██║   ██║██║██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██║     ████╗ ████║██║████╗  ██║    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     
# ██║   ██║██║██████╔╝   ██║   ██║   ██║███████║██║     ██╔████╔██║██║██╔██╗ ██║    ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     
# ╚██╗ ██╔╝██║██╔══██╗   ██║   ██║   ██║██╔══██║██║     ██║╚██╔╝██║██║██║╚██╗██║    ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     
#  ╚████╔╝ ██║██║  ██║   ██║   ╚██████╔╝██║  ██║███████╗██║ ╚═╝ ██║██║██║ ╚████║    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
#   ╚═══╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
## Logging
log_prefix="RALVIN | virtualmin-installer |"

# Get the installer
curl -o ./virtualmin-installer.sh http://software.virtualmin.com/gpl/scripts/install.sh
chmod +x ./virtualmin-installer.sh
echo "${log_prefix} got latest installer" >> ./RALVIN.log

# Run the installer
echo "${log_prefix} triggering install with hostname ${fqdn_hostname}" >> ./RALVIN.log
./virtualmin-installer.sh --hostname "${fqdn_hostname}" --force
echo "${log_prefix} finished install with hostname ${fqdn_hostname}" >> ./RALVIN.log


# Update the password
if [[ ! -z $virtualmin_user_name && ! -z $virtualmin_password ]]; then
	sudo /usr/libexec/webmin/changepass.pl /etc/webmin $virtualmin_user_name $virtualmin_password
	echo "${log_prefix} password updated for Virtualmin user ${virtualmin_user_name}" >> ./RALVIN.log
fi



# ██╗   ██╗██╗██████╗ ████████╗██╗   ██╗ █████╗ ██╗     ███╗   ███╗██╗███╗   ██╗    ██████╗  ██████╗ ███████╗████████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     
# ██║   ██║██║██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██║     ████╗ ████║██║████╗  ██║    ██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     
# ██║   ██║██║██████╔╝   ██║   ██║   ██║███████║██║     ██╔████╔██║██║██╔██╗ ██║    ██████╔╝██║   ██║███████╗   ██║       ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     
# ╚██╗ ██╔╝██║██╔══██╗   ██║   ██║   ██║██╔══██║██║     ██║╚██╔╝██║██║██║╚██╗██║    ██╔═══╝ ██║   ██║╚════██║   ██║       ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     
#  ╚████╔╝ ██║██║  ██║   ██║   ╚██████╔╝██║  ██║███████╗██║ ╚═╝ ██║██║██║ ╚████║    ██║     ╚██████╔╝███████║   ██║       ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
#   ╚═══╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝    ╚═╝      ╚═════╝ ╚══════╝   ╚═╝       ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
#
# Logging
log_prefix="RALVIN | virtualmin-post-install |"

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
if [ ! -z "${myqsl_root_password}" ]; then
	virtualmin set-mysql-pass --user root --pass "${myqsl_root_password}"
	echo "${log_prefix} Updated root password for MySQL" >> ./RALVIN.log
fi

# Set MySQL server memory size
sed_param=s/mysql_size=.*/mysql_size=${MYSQL_MEMORY}/  
sed -i "$sed_param" $CONFIG
echo "${log_prefix} MySQL memory setting is ${MYSQL_MEMORY}" >> ./RALVIN.log


# Enable preloading of virtualmin libraries
sed -i 's/preload_mode=.*/preload_mode=1/' $CONFIG
echo "${log_prefix} Enabled Virtualmin library preloading" >> ./RALVIN.log

# Enable ClamAV server
sed -i 's/virus=.*/virus=1/' $CONFIG
echo "${log_prefix} Enabled ClamAV server" >> ./RALVIN.log

# Enable SpamAssassin server
sed -i 's/spam=.*/spam=1/' $CONFIG
echo "${log_prefix} Enabled SpamAssassin server" >> ./RALVIN.log

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

#echo "${log_prefix} Enabled quotas" >> ./RALVIN.log 

# Enable hashed passwords
sed -i 's/hashpass=.*/hashpass=1/' $CONFIG
echo "${log_prefix} Enabled hashed passwords" >> ./RALVIN.log

# Enable wizard_run flag
echo "wizard_run=1" >> $CONFIG
sed -i 's/wizard_run=.*/wizard_run=1/' $CONFIG
echo "${log_prefix} Manually added wizard_run flag" >> ./RALVIN.log

# Redirect non-SSL calls to the admin panel to SSL
sed -i 's/ssl_redirect=.*/ssl_redirect=1/' /etc/webmin/miniserv.conf
echo "${log_prefix} Enabled non-SSL to SSL redirect for Webmin panel" >> ./RALVIN.log

# Enable SSL by default
virtualmin set-global-feature --default-on ssl
echo "${log_prefix} SSL enabled" >> ./RALVIN.log

# Disable AWstats by default
virtualmin set-global-feature --default-off virtualmin-awstats 
echo "${log_prefix} AWStats disabled" >> ./RALVIN.log

# Disable DAV by default
virtualmin set-global-feature --default-off virtualmin-dav 
echo "${log_prefix} DAV disabled" >> ./RALVIN.log

# Change autoconfig script to have hard-coded STARTTLS
virtualmin modify-mail --all-domains --autoconfig
sudo virtualmin modify-template --id 0 --setting autoconfig --value "$(cat ./resources/autoconfig.xml | tr '\n' ' ')"
sudo virtualmin modify-template --id 0 --setting autodiscover --value "$(cat ./resources/autodiscover.xml | tr '\n' ' ')"
echo "${log_prefix} autoconfig enabled and STARTTLS hard-coded" >> ./RALVIN.log


# Check config?

# fin
echo "${log_prefix} Virtualmin Post-Install Wizard setup complete" >> ./RALVIN.log



# ██████╗ ███████╗███████╗ █████╗ ██╗   ██╗██╗  ████████╗    ██████╗  ██████╗ ███╗   ███╗ █████╗ ██╗███╗   ██╗
# ██╔══██╗██╔════╝██╔════╝██╔══██╗██║   ██║██║  ╚══██╔══╝    ██╔══██╗██╔═══██╗████╗ ████║██╔══██╗██║████╗  ██║
# ██║  ██║█████╗  █████╗  ███████║██║   ██║██║     ██║       ██║  ██║██║   ██║██╔████╔██║███████║██║██╔██╗ ██║
# ██║  ██║██╔══╝  ██╔══╝  ██╔══██║██║   ██║██║     ██║       ██║  ██║██║   ██║██║╚██╔╝██║██╔══██║██║██║╚██╗██║
# ██████╔╝███████╗██║     ██║  ██║╚██████╔╝███████╗██║       ██████╔╝╚██████╔╝██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
# ╚═════╝ ╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝       ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
#
# Logging
log_prefix="RALVIN | create-default-domain |"

# Generate a random password for the default domain user account
webmin_password=$(date +%s|sha256sum|sha256sum|base64|head -c 32)

# Create a virtual site for the default domain
virtualmin create-domain --domain "${fqdn_hostname}" --pass "${webmin_password}" --default-features

declare HOME_DIR=$(virtualmin list-domains | grep "${fqdn_hostname}" | awk -F" " '{print $2}')

if [ ! -z "$HOME_DIR" ]; then
	# Copy default server status page
	cp ./resources/index.html "/home/${HOME_DIR}/public_html/index.html"
	echo "${log_prefix} Created /home/${HOME_DIR}/public_html/index.html" >> ./RALVIN.log
	
	# Update status page with correct domain
	sed -i -e "s/example\.com/${fqdn_hostname}/g" "/home/${HOME_DIR}/public_html/index.html"
fi

# Generate and install lets encrypt certificate
virtualmin generate-letsencrypt-cert --domain "$1" >> RALVIN.ssl.log

virtualmin install-service-cert --domain "$1" --service postfix >> RALVIN.ssl.log
virtualmin install-service-cert --domain "$1" --service usermin >> RALVIN.ssl.log
virtualmin install-service-cert --domain "$1" --service webmin >> RALVIN.ssl.log
virtualmin install-service-cert --domain "$1" --service dovecot >> RALVIN.ssl.log
virtualmin install-service-cert --domain "$1" --service proftpd >> RALVIN.ssl.log

echo "${log_prefix} LetsEncrypt certificate requested and copied to services (see RALVIN.ssl.log for more info)" >> ./RALVIN.log



# ██████╗ ██╗  ██╗██████╗     ██╗███╗   ██╗██╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗
# ██╔══██╗██║  ██║██╔══██╗    ██║████╗  ██║██║    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝
# ██████╔╝███████║██████╔╝    ██║██╔██╗ ██║██║       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ ███████╗
# ██╔═══╝ ██╔══██║██╔═══╝     ██║██║╚██╗██║██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ╚════██║
# ██║     ██║  ██║██║         ██║██║ ╚████║██║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████║
# ╚═╝     ╚═╝  ╚═╝╚═╝         ╚═╝╚═╝  ╚═══╝╚═╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#
# Logging
log_prefix="RALVIN | php-ini-tweaks |"

# Add PHP 8.1 php.ini to webmin
echo "/etc/opt/remi/php81/php.ini" | sudo tee -a /etc/webmin/phpini/config
echo $(sudo head -c -1 /etc/webmin/phpini/config) | sudo tee /etc/webmin/phpini/config
echo "${log_prefix} Added PHP 8.1 php.ini to Webmin" >> ./RALVIN.log

# Tweaks various settings for php.ini
virtualmin modify-php-ini --all-domains --ini-name upload_max_filesize --ini-value 32M
virtualmin modify-php-ini --all-domains --ini-name post_max_size  --ini-value 32M
echo "${log_prefix} upload_max_filesize and post_max_size set to 32M" >> ./RALVIN.log

# Add GNU Terry Pratchett 
tee -a /etc/httpd/conf/httpd.conf > /dev/null <<EOT

#  ╔═╗╔╗╔╦ ╦  ╔╦╗┌─┐┬─┐┬─┐┬ ┬  ╔═╗┬─┐┌─┐┌┬┐┌─┐┬ ┬┌─┐┌┬┐┌┬┐
#  ║ ╦║║║║ ║   ║ ├┤ ├┬┘├┬┘└┬┘  ╠═╝├┬┘├─┤ │ │  ├─┤├┤  │  │ 
#  ╚═╝╝╚╝╚═╝   ╩ └─┘┴└─┴└─ ┴   ╩  ┴└─┴ ┴ ┴ └─┘┴ ┴└─┘ ┴  ┴ 
<IfModule headers_module>
  header set X-Clacks-Overhead "GNU Terry Pratchett"
</IfModule>
EOT

echo "${log_prefix} Added GNU Terry Pratchett to httpd.conf" >> ./RALVIN.log

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
log_prefix="RALVIN | enable-2fa |"

# Copy the CPAN config file
[[ ! -e "/root/.cpan/CPAN" ]] && mkdir -p /root/.cpan/CPAN && echo "${log_prefix} Made CPAN directory" >> ./RALVIN.log
[[ ! -e "/root/.cpan/CPAN/MyConfig.pm" ]] && cp ./resources/CPAN.pm /root/.cpan/CPAN/MyConfig.pm && chown root /root/.cpan/CPAN/MyConfig.pm && echo "${log_prefix} Copied CPAN config from template" >> ./RALVIN.log

# Install the right modules
PACKAGES="Archive::Tar Authen::OATH Digest::HMAC Digest::SHA Math::BigInt Moo Moose Module::Build Test::More Test::Needs Type::Tiny Types::Standard"
cpan install $PACKAGES
echo "${log_prefix} Installed perl packages" >> ./RALVIN.log

# Enable Google Authenticator
echo "twofactor_provider=totp" | sudo tee -a /etc/webmin/miniserv.conf
echo "${log_prefix} Enabled Google Authenticator 2FA for Webmin. You will need to enroll a user manually." >> ./RALVIN.log



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
log_prefix="RALVIN | harden-postfix |"

# Backup the current/default config
postconf | sudo tee /root/postfix.main.cf.$(date "+%F-%T")
echo "${log_prefix} Backed up original config to /root/postfix.main.cf.$(date "+%F-%T")" >> ./RALVIN.log

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
echo "${log_prefix} Postfix hardened and reloaded" >> ./RALVIN.log


printf "\n"
printf "|| RALVIN has completed \n"
printf "|| ========================================================\n"
printf "|| FQDN:                           ${fqdn_hostname} \n"
printf "|| Sudo user:                      ${sudo_user_name} \n"
printf "|| Sudo password:                  ${sudo_user_password} \n"
printf "|| Public key:                     ${sudo_user_pubkey} \n"
printf "|| MySQL root password:            ${myqsl_root_password} \n"
printf "|| Webmin default domain password: ${webmin_password} \n"
printf "|| Virtualmin user:                ${virtualmin_user_name} \n"
printf "|| Virtualmin password:            ${virtualmin_password} \n"
printf "|| Virtualmin panel:               https://${fqdn_hostname}:10000 \n"

