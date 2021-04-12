#!/bin/bash
#shellcheck disable=SC2129
# Lidarr installer for swizzin
# Author: liara
# Copyright (C) 2019 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

user=$(cut -d: -f1 < /root/.master.info)
distribution=$(lsb_release -is)
version=$(lsb_release -cs)
#shellcheck source=sources/functions/mono
. /etc/swizzin/sources/functions/mono
mono_repo_setup
apt_install libmono-cil-dev libchromaprint-tools

echo_progress_start "Fetching Lidarr source files"
wget -O /tmp/lidarr.tar.gz "$(curl -s https://api.github.com/repos/Lidarr/Lidarr/releases | grep linux.tar.gz | grep browser_download_url | head -1 | cut -d \" -f 4)" >> $log 2>&1
echo_progress_done "Source fetched"

echo_progress_start "Extracting source"
tar xfv /tmp/lidarr.tar.gz --directory /opt/ >> $log 2>&1
rm -rf /tmp/lidarr.tar.gz
chown -R "${user}": /opt/Lidarr
echo_progress_done "Source extracted"

echo_progress_start "Creating configuration and service files"
if [[ ! -d /home/${user}/.config/Lidarr/ ]]; then mkdir -p "/home/${user}/.config/Lidarr/"; fi
cat > "/home/${user}/.config/Lidarr/config.xml" << LID
<Config>
  <Port>8686</Port>
  <UrlBase>lidarr</UrlBase>
  <BindAddress>*</BindAddress>
  <EnableSsl>False</EnableSsl>
  <LogLevel>Info</LogLevel>
  <LaunchBrowser>False</LaunchBrowser>
</Config>
LID
chown -R "${user}": "/home/${user}/.config"
cat > /etc/systemd/system/lidarr.service << LID
[Unit]
Description=lidarr for ${user}
After=syslog.target network.target

[Service]
Type=simple
User=${user}
Group=${user}
Environment="TMPDIR=/home/${user}/.tmp"
ExecStart=/usr/bin/mono /opt/Lidarr/Lidarr.exe -nobrowser
WorkingDirectory=/home/${user}/
Restart=on-failure

[Install]
WantedBy=multi-user.target
LID
echo_progress_done "Services configured"

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    sleep 10
    bash /usr/local/bin/swizzin/nginx/lidarr.sh
    systemctl reload nginx
    echo_progress_done "Nginx configured"
else
    echo_info "Lidarr will run on port 8686"
fi

echo_progress_start "Enabling auto-start and executing Lidarr"
systemctl enable -q --now lidarr
echo_progress_done

echo_success "Lidarr installed"

touch /install/.lidarr.lock
