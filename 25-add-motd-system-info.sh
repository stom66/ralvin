#!/bin/bash

# Enables an MotD with system info and basic "LS" logo

# Logging
declare PREFIX="RALVIN | add-motd |"

sed -i 's/#\?\(PrintMotd\s*\).*$/\1 no/' /etc/ssh/sshd_config

echo "${PREFIX} Updated sshd_config" >> ./RALVIN.log

systemctl restart sshd
cp ./resources/motd.ls.sh /etc/profile.d/sysinfo.motd.sh
echo "${PREFIX} Installed and enabled SysInfo MotD" >> ./RALVIN.log

chmod +x /etc/profile.d/sysinfo.motd.sh
echo "${PREFIX} SSH Daemon restarted" >> ./RALVIN.log
