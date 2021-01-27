#!/bin/bash
# Nextcloud updates

if [[ -f /install/.nextcloud.lock ]]; then
    if ! grep -q 'set $path_info' /etc/nginx/apps/nextcloud.conf; then
        echo_log_only "fixing nextcloud nginx conf"
        bash /etc/swizzin/scripts/nginx/nextcloud.sh
        systemctl reload nginx
    fi
fi
