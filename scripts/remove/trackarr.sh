#!/usr/bin/env bash

systemctl disable --now -q trackarr

rm -rf /opt/trackarr
userdel -rf trackarr

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/trackarr.conf
    systemctl reload nginx
fi

rm /install/.trackarr.lock
