#!/bin/bash

systemctl disable --now -q moviematch
rm /etc/systemd/system/moviematch.service

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/moviematch.conf
    systemctl reload nginx
fi

userdel moviematch -f -r >> $log 2>&1

rm /install/.moviematch.lock
