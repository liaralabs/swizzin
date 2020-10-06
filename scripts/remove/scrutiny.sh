#!/bin/bash

scrutinydir="/opt/scrutiny"

userdel -rf scrutiny

systemctl disable -q --now scrutiny-web
systemctl disable -q --now scrutiny-collector.timer
systemctl disable -q --now scrutiny-collector.service

rm -rf $scrutinydir

rm /install/.scrutiny.lock