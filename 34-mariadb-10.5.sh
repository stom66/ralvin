#!/bin/bash

#Setup and install MariaDB 10.5

# Logging
declare PREFIX="RALVIN | mariadb-10.5 |"

dnf module enable -y mariadb:10.5
dnf install -y mariadb

echo "${PREFIX} Upgraded MariaDB to $(mariadb -V)" >> ./RALVIN.log
echo "${PREFIX} MariaDB service restarted " >> ./RALVIN.log