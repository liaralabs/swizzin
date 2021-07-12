#!/usr/bin/env bash

paths+=("/home/$loguser/.local/share/data/qBittorrent/logs/qbittorrent.log")
commands+=("journalctl -u qbittorrent@$loguser")
version="$(/usr/bin/qbittorrent-nox --version | awk {'print $2'})"
