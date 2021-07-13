#!/bin/bash

if ask "Would you like to purge the configuration?" Y; then
    rm -rf "/home/$(swizdb get radarr/owner)/.config/Radarr"
    swizdb clear "sonarr/owner"
fi

systemctl disable --now -q radarr
rm /etc/systemd/system/radarr.service
systemctl daemon-reload -q
rm -rf /opt/Radarr

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/radarr.conf
    systemctl reload nginx
fi

rm /install/.radarr.lock
