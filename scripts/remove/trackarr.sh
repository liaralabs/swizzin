#!/usr/bin/env bash

rm -rf /opt/trackarr
userdel -rf trackarr

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/trackarr.conf
    systemctl nginx reload
fi

rm /install/.trackarr.lock
