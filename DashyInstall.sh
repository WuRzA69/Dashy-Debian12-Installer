#!/bin/bash

#############################################################################
#                                                                           #
#    This Script is a All in One install script for Dashy Dashboard         #
#    It was created to install Dashy in Debian12                            #
#                                                                           #
#    The script is designed around some errors/unknowns in the readme.md    #
#                                                                           #
#    * Dashy only works with NodeJS16                                       #
#    * With this script Dashy run with systemd in the backgrund             #
#    * Auto rebuild after saving conf.yml                                   #
#                                                                           #
#############################################################################

#Variables
VERSION=v16.0.0
DISTRO=linux-x64
IP=$(hostname -I | awk '{print $1}')
PORT=4000

#Installing some stuff
apt install -y git wget curl 

#Installing NodeJS 16 via binary
VERSION=v16.0.0
DISTRO=linux-x64
wget https://nodejs.org/dist/$VERSION/node-$VERSION-$DISTRO.tar.xz
mkdir -p /usr/local/lib/nodejs
tar -xJvf node-$VERSION-$DISTRO.tar.xz -C /usr/local/lib/nodejs 
export PATH=/usr/local/lib/nodejs/node-$VERSION-$DISTRO/bin:$PATH
ln -s /usr/local/lib/nodejs/node-$VERSION-$DISTRO/bin/node /usr/bin/node
ln -s /usr/local/lib/nodejs/node-$VERSION-$DISTRO/bin/npm /usr/bin/npm
ln -s /usr/local/lib/nodejs/node-$VERSION-$DISTRO/bin/npx /usr/bin/npx


#install yarn via apt
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
apt update
apt install -y --no-install-recommends yarn

#Move to dashy dir, clone the git repo
cd /opt
git clone https://github.com/Lissy93/dashy.git
cd dashy

#Do the yarnsy
yarn
yarn build

#Create systemd service for Dashy
cat > /etc/systemd/system/dashy.service << EOF
[Unit]
Description=Dashy homelab dashboard
After=network-online.target

[Service]
Environment="PORT=$PORT"
WorkingDirectory=/opt/dashy
ExecStart=yarn start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

#Create systemd service to rebuild dashy on config change
cat > /etc/systemd/system/dashy-rebuild.service << EOF
[Unit]
Description=Rebuild Dashy on Config Changes

[Service]
Type=oneshot
WorkingDirectory=/opt/dashy
ExecStart=yarn build
EOF

#Create systemd path to call service on config file change
cat > /etc/systemd/system/dashy-rebuild.path << EOF
[Unit]
Description=Monitor Dashy Config for Changes

[Path]
PathChanged=/opt/dashy/public/conf.yml

[Install]
WantedBy=multi-user.target
EOF

#Make systemd aware that we just changed stuff
systemctl daemon-reload

#And start our services!
systemctl enable --now dashy
systemctl enable --now dashy-rebuild.path


#Give User Info
clear
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                                                   "
echo "                 Script is finished                "
echo "                                                   "
echo "       Dashy is runing on $IP:$PORT                "
echo "                                                   "
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"