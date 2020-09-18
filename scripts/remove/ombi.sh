#!/bin/bash
systemctl disable -q ombi
systemctl stop -q ombi
rm /etc/systemd/system/ombi.service
rm -f /etc/nginx/apps/ombi.conf
systemctl reload nginx

apt remove -y -q ombi >> /dev/null 2>&1

if [[ -d /opt/ombi ]]; then
  rm -rf /opt/ombi
  rm -rf /etc/ombi
fi

if [[ -d /opt/Ombi ]]; then
  rm -rf /opt/Ombi
  rm -rf /etc/Ombi
fi

rm /install/.ombi.lock
