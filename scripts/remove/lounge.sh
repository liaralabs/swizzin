#!/bin/bash

systemctl disable -q lounge >> /dev/null 2>&1
systemctl stop -q lounge

npm uninstall -g thelounge --save >> /dev/null 2>&1

deluser lounge --remove-home >> /dev/null 2>&1
rm -rf /home/lounge # just in case

rm -f /etc/nginx/apps/lounge.conf
systemctl reload nginx -q

rm -f /etc/systemd/system/lounge.service
rm -f /install/.lounge.lock
