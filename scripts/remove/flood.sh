#!/bin/bash
# Flood uninstaller
# Author: liara

systemctl disable flood --now -q
rm /etc/systemd/system/flood.service
npm -g remove flood >> "$log" 2>&1

userdel -rf flood

if [ -f "/etc/nginx/apps/flood.conf" ]; then
    rm /etc/nginx/apps/flood.conf
    systemctl reload nginx
fi

rm /install/.flood.lock
