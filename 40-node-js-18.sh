#!/bin/bash

# Install NodeJS v18.x

# Logging
declare PREFIX="RALVIN | node-js |"


dnf module enable -y nodejs:18

dnf install -y nodejs
echo "${PREFIX} Installed NodeJS $(node -v)" >> ./RALVIN.log
echo "${PREFIX} Installed NPM $(npm -v)" >> ./RALVIN.log