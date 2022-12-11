#/bin/bash
# Converts a CentOS 8 install to a Rocky 8 install.

# Tested and working on AWS Lightsail with CentOS 8 as on 2022-12-06

# Curl the migrate2rocky script from the offical repo and run it

# Update curent system
sudo dnf update -y

# Curl the script and enable execution
curl https://raw.githubusercontent.com/rocky-linux/rocky-tools/main/migrate2rocky/migrate2rocky.sh -o migrate2rocky.sh
chmod u+x migrate2rocky.sh

# Run the update script, -r flag triggers the migration
sudo ./migrate2rocky.sh -r
