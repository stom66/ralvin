#!/bin/bash

#Setup and install PHP 8.1 from Remi repos

# Logging
declare PREFIX="RALVIN | php-8.1 |"

dnf config-manager --set-enabled powertools
dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
echo "${PREFIX} Enabled PHP Remi 8.1 Repo" >> ./RALVIN.log

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



# Add php.ini to webmin
echo "/etc/opt/remi/php81/php.ini" | sudo tee -a /etc/webmin/phpini/config
echo $(sudo head -c -1 /etc/webmin/phpini/config) | sudo tee /etc/webmin/phpini/config
echo "${PREFIX} Added PHP 8.1 php.ini to Webmin" >> ./RALVIN.log

#make this the default when 
#ln -s /usr/bin/php74 /usr/bin/php
#echo "${PREFIX} Created link in /usr/bin/php" >> ./RALVIN.log
