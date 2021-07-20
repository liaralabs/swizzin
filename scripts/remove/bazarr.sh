#!/bin/bash

systemctl disable --now -q bazarr
rm -rf /etc/systemd/system/bazarr.service

rm -rf /opt/bazarr
rm -rf /opt/.venv/bazarr
if [ -z "$(ls -A /opt/.venv)" ]; then
    rm -rf /opt/.venv
fi

rm -rf /etc/nginx/apps/bazarr.conf
systemctl reload nginx

rm -rf /install/.bazarr.lock
