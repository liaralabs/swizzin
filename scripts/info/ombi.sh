#!/usr/bin/env bash

paths+=(/etc/Ombi/Logs/*.txt)
commands+=("journalctl -u ombi")
version="$(dpkg -s ombi | grep ^Version | cut -f2 -d' ')"
