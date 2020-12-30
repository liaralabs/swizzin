#!/usr/bin/env bash

systemctl disable --now -q trackarr

rm -rf /opt/trackarr >> "$log" 2>&1
userdel -rf trackarr >> "$log" 2>&1

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/trackarr.conf
    systemctl reload nginx
fi

rm /install/.trackarr.lock
