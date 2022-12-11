# RALVIN

# Note: under development. Here be dragons.

## Rocky Amazon Lightsail Virtualmin Installer

This script is designed to be run on a fresh installation of Rocky 8. It supports both AWS and non-AWS systems. It has been tested on the 512MB+ Lightsail platforms.

It was developed for personal use, and I take no responsibility for any problems it may cause. It is minimally configurable abnd based on my own use-cases.

It will install all required dependencies for the following: 

* Virtualmin LAMP
* PHP 7.4 (via dnf) and 8.1 (via Remi)
* NodeJS 18.x
* MariaDB 10.5


It will also change various config file settings and add the key provided to the authorised_keys file for the default centos account.

---

## How to use:

###  Edit and use launch.sh:

Example commands to clone the scripts from Git and open launch.sh for editing:
```bash
sudo dnf install -y -q git nano
git clone https://github.com/stom66/ralvin/ ralvin && cd ralvin
chmod +x launch.sh && chmod +x ralvin.sh
nano launch.sh
```

Edit the file, then run:
```bash
sudo ./launch.sh
```

### (Or) Run directly with parameters (be sure to set your own key and passwords):

```bash

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
	--webmin-password "yourPassword2" \
	--aws-access-key "EXAMPLEACCESSKEY" \
	--aws-secret-key "EXAMPLESECRETKEY"
	
```


### Post-install

An installation log is created in the directory it was run from in `ralvin.log`. There is also `ralvin.ssl.log` which contains the output of the LetsEncrypt request.

Assuming the installation completed succeffully you should be able to log into the Virtualmin admin panel at the address shown in your terminal.

Some thing to do after logging in:

* Reboot the system!
* Visit the defualt domain (if used) and check the status page is working
* Enable 2FA for the Virtualmin Panel by running `enable-2fa.sh` and then enabling it under *Webmin -> Webmin Users -> Two-Factor Authentication*
* Set a nice login background under Webmin -> Webmin Configuration -> Webmin Themes -> Theme Backgrounds
* Enable bandidth monitoring under *Virtualmin -> System Settings -> Bandwidth Monitoring*. You'll also need to setup a reasonable quota as the default is unlimited
* Enable DKIM under Virtualmin -> Email Settings -> DomainKeys Identified Mail
* Enable mail client auto-configuration under Virtualmin -> Email Settings -> Mail Client Configuration
* Check the mail client auto-configuration autodiscover and autocondif urls display the right settings:
  * https://domain.com/autodiscover/autodiscover.xml?emailaddress=user@domain.com
  * https://domain.com/cgi-bin/autoconfig.cgi?emailaddress=user@domain.com

	

---

## ToDo

* Enable quotas in grub
* Configure Postfix [mostly done]
* Cludge the autodiscover file, or:
* Find suitable Postfix config to correctly populate mail autoconfig template (and avoid need for hardcoding)
* Generate a keypair for the centos user and output the public key
* Option to increase SSH timeout?
* Enable snapshots via AWS CLI

* ~~Add custom SSH port?~~
* ~~Open ports via AWS CLI~~
* ~~Add PHP 7.* ini files to Virtualmin config~~
* ~~Apply GNU Terry Pratchett~~
* ~~Configure a default domain~~
* ~~Import simple status page for default virtual server~~
* ~~Install and enable 2FA, presenting a QR code if possible~~

