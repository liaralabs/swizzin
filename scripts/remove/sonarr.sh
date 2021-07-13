#!/bin/bash

if ask "Would you like to purge the configuration?" Y; then
    apt_remove --purge sonarr
    rm -rf /var/lib/sonarr
    rm -rf /usr/lib/sonarr
    swizdb clear "sonarr/owner"
else
    apt_remove sonarr
fi
if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/sonarr.conf
    systemctl reload nginx >> "$log" 2>&1
fi

rm /install/.sonarr.lock
