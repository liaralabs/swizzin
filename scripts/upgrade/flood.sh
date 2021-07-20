#!/bin/bash
# Flood Upgrade Script
# Author: liara

users=($(cut -d: -f1 < /etc/htpasswd))

if [ ! -f /install/.flood.lock ]; then
    echo_warn "Flood is not installed"
    exit 0
fi

if [[ ! $(which node-gyp) ]]; then
    npm install -g node-gyp >> $log 2>&1
fi

for u in "${users[@]}"; do
    port=$(grep floodServerPort /home/$u/.flood/config.js | cut -d: -f2 | sed 's/[^0-9]*//g')
    salt=$(grep secret /home/$u/.flood/config.js | cut -d\' -f2)
    if [[ $(systemctl is-active flood@$u) == "active" ]]; then
        active=yes
        systemctl stop flood@$u
    fi
    cd /home/$u/.flood
    sudo -u $u git pull || {
        sudo -u $u git reset HEAD --hard
        sudo -u $u git pull
    }
    rm -rf config.js
    cp -a config.template.js config.js
    sed -i "s/floodServerPort: 3000/floodServerPort: $port/g" config.js
    sed -i "s/socket: false/socket: true/g" config.js
    sed -i "s/socketPath.*/socketPath: '\/var\/run\/${u}\/.rtorrent.sock'/g" config.js
    sed -i "s/secret: 'flood'/secret: '$salt'/g" config.js
    if [[ ! -f /install/.nginx.lock ]]; then
        sed -i "s/floodServerHost: '127.0.0.1'/floodServerHost: '0.0.0.0'/g" config.js
    elif [[ -f /install/.nginx.lock ]]; then
        sed -i "s/floodServerHost: '0.0.0.0'/floodServerHost: '127.0.0.1'/g" /home/$u/.flood/config.js
        sed -i "s/baseURI: '\/'/baseURI: '\/flood'/g" /home/$u/.flood/config.js
    fi
    sudo -H -u $u npm install
    sudo -H -u $u npm run build || {
        rm -rf /home/$u/.flood/node_modules
        sudo -H -u $u npm install
        sudo -H -u $u npm run build
    }
    if [[ $active == "yes" ]]; then
        systemctl start flood@$u
    fi
done
