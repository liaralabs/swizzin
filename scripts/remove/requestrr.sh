#!/bin/bash
systemctl disable --now -q requestrr
rm /etc/systemd/system/requestrr.service
systemctl daemon-reload -q
rm -rf /opt/requestrr
userdel requestrr -r

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/requestrr.conf
    systemctl reload nginx
fi

rm /install/.requestrr.lock
