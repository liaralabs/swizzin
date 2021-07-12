#!/usr/bin/env bash

# commands+=('rtorrent')
paths+=("/home/$loguser/.rtorrent.rc")
commands+=("dpkg -s rtorrent")
commands+=("journalctl -u rtorrent@$loguser")
version="$(rtorrent -h | head -1 | awk '{print $NF}')"
