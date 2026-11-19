#!/usr/bin/env bash

set -e

# Use sudo only when not running as root
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Configure NodeSource repository
$SUDO tee /etc/yum.repos.d/nodesource-nodejs.repo > /dev/null <<EOF
[nodesource-nodejs]
name=Node.js Packages
baseurl=https://rpm.nodesource.com/pub_23.x/nodistro/nodejs/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://rpm.nodesource.com/gpgkey/ns-operations-public.key
EOF

# Install Node.js
$SUDO yum install -y nodejs

#
sudo adduser app-user                                         
sudo mv /tmp/sample-app /home/app-user                        
sudo chown -R app-user /home/app-user/sample-app              
sudo npm install pm2@latest -g                                
eval "$(sudo -u app-user pm2 startup -u app-user | tail -n1)"

# Verify installation
node --version
npm --version