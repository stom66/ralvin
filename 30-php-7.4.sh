#!/bin/bash

#Setup and install PHP 7.4 from Remi repos

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

#make this the default when 
#ln -s /usr/bin/php74 /usr/bin/php
#echo "${PREFIX} Created link in /usr/bin/php" >> ./RALVIN.log
