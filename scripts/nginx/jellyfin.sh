#!/usr/bin/env bash
#
. /etc/swizzin/sources/functions/utils
# Set the required variables
log="/root/logs/swizzin.log"
username="$(_get_master_username)"
#
# A functions for reused commands.
function reused_commands () {
    sed -r 's#<string>0.0.0.0</string>#<string>127.0.0.1</string>#g' -i "/etc/jellyfin/system.xml"
    sed -r 's#<BaseUrl />#<BaseUrl>/jellyfin</BaseUrl>#g' -i "/etc/jellyfin/system.xml"
    chown jellyfin:jellyfin "/etc/jellyfin/system.xml"
}
#
# Do this for jellyfin if is not already installed
if [[ ! -f /install/.jellyfin.lock ]]; then
    reused_commands
fi
#
# Do this for jellyfin if is already installed
if [[ -f /install/.jellyfin.lock ]]; then
    systemctl -q stop "jellyfin.service"
	#
    reused_commands
    #
    systemctl -q start "jellyfin.service"
fi
#
# Create our nginx application conf for jellyfin
cat > /etc/nginx/apps/jellyfin.conf <<-NGINXCONF
location /jellyfin {
    proxy_pass https://127.0.0.1:8920;
    #
    proxy_pass_request_headers on;
    #
    proxy_set_header Host \$host;
    #
    proxy_http_version 1.1;
    #
    proxy_set_header X-Real-IP              \$remote_addr;
    proxy_set_header X-Forwarded-For        \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto      \$scheme;
    proxy_set_header X-Forwarded-Protocol   \$scheme;
    proxy_set_header X-Forwarded-Host       \$http_host;
    #
    proxy_set_header Upgrade                \$http_upgrade;
    proxy_set_header Connection             \$http_connection;
    #
    proxy_set_header X-Forwarded-Ssl        on;
    #
    proxy_redirect                          off;
    proxy_buffering                         off;
    auth_basic                              off;
}
NGINXCONF