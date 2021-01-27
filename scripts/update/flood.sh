#!/usr/bin/env bash

if [ -f /etc/systemd/system/flood@.service ]; then

    ## somehow ask if flood can be migrated
    if ask "Flood should be upgraded to a maintained fork. A reconfiguration will be necessary. Continue?"; then
        echo_progress_start "Removing old flood"
        #!/bin/bash
        # Flood uninstaller
        # Author: liara
        users=($(cut -d: -f1 < /etc/htpasswd))
        for u in "${users[@]}"; do
            systemctl disable -q flood@$u
            systemctl stop -q flood@$u
            rm -rf /home/$u/.flood
            rm -rf /etc/nginx/conf.d/$u.flood.conf
        done
        rm -rf /etc/nginx/apps/flood.conf
        if [[ ! -f /install/.rutorrent.lock ]]; then
            rm -rf /etc/nginx/apps/rindex.conf
            rm -f /etc/nginx/apps/${u}.scgi.conf
        fi
        rm -rf /etc/systemd/system/flood@.service
        systemctl reload nginx
        rm -rf /install/.flood.lock

        echo_progress_start "Installing new flood"
        bash /etc/swizzin/scripts/install/flood.sh
    fi

fi
