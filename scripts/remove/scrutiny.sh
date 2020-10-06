#!/bin/bash
# Scrutiny installer by flying_sausages for Swizzin 2020
# GPLv3 applies

scrutinydir="/opt/scrutiny"

systemctl disable -q --now scrutiny-web
systemctl disable -q --now scrutiny-collector.timer
systemctl disable -q --now scrutiny-collector.service

userdel -rf scrutiny

rm /install/.scrutiny.lock