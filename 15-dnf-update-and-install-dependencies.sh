#!/bin/bash

# Runs dnf update and installs various dependencies

# Logging
declare PREFIX="RALVIN | dnf-update |"

# dnf update
dnf update -y
echo "${PREFIX} Updated existing packages" >> ./RALVIN.log

# Add epel-release
dnf install -y epel-release

# Add other dependencies
PACKAGES=""
PACKAGES="${PACKAGES} tmux wget nano gcc gcc-c++ gem git"
PACKAGES="${PACKAGES} htop lm_sensors make ncdu perl perl-Authen-PAM"
PACKAGES="${PACKAGES} perl-CPAN ruby-devel rubygems scl-utils util-linux"
PACKAGES="${PACKAGES} zip unzip"

dnf install -y $PACKAGES
echo "${PREFIX} Installed the following packages:" >> ./RALVIN.log
echo "${PREFIX} ${PACKAGES}" >> ./RALVIN.log