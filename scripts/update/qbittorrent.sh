#!/bin/bash

if [[ -f /install/.qbittorrent.lock ]]; then
    #Check systemd service for updates
    type=simple
    if [[ $(systemctl --version | awk 'NR==1 {print $2}') -ge 240 ]]; then
        unittype=exec
    fi
    if ! grep -q Type=$unittype /etc/systemd/system/qbittorrent@.service; then
        sed -i "s/Type=.*/Type=$unittype/g" /etc/systemd/system/qbittorrent@.service
        reloadsys=true
    fi
    if grep -q "qbittorrent-nox -d" /etc/systemd/system/qbittorrent@.service; then
        sed -i 's|/usr/bin/qbittorrent-nox -d|/usr/bin/qbittorrent-nox|g' /etc/systemd/system/qbittorrent@.service
        reloadsys=true
    fi
    if [[ $reloadsys == true ]]; then
        systemctl daemon-reload
        echo_info "qBittorrent systemd services have been updated. Please restart qBittorrent services at your convenience."
    fi
    #End systemd service updates
    if ! grep -q "proxy_connect_timeout" /etc/nginx/apps/qbittorrent.conf; then
        echo_info "Updating nginx config for qbit"
        /etc/swizzin/scripts/nginx/qbittorrent.sh
        systemctl reload nginx
    fi
fi
