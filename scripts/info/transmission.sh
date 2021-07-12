#!/usr/bin/env bash

commands+=('transmission-daemon --version')
commands+=("journalctl -u transmission@$loguser")
paths+=("/home/$loguser/.config/transmission-daemon/settings.json") # TODO is it?
version="$(transmission-daemon --version | awk)"
