#!/bin/bash
. /etc/swizzin/sources/functions/requestrr

if [[ ! -f /install/.requestrr.lock ]]; then
    echo_error "Requestrr not detected. Exiting!"
    exit 1
fi

_requestrr_download
echo_progress_start "Replacing source code"

unzip -q /tmp/requestrr.zip -d /tmp/ >> "$log" 2>&1
rm /tmp/requestrr.zip
cp -RT /tmp/requestrr*/ /opt/requestrr
chown -R requestrr:requestrr /opt/requestrr
rm -rf /tmp/requestrr*
echo_progress_done "Extracted and overwrote existing files."

echo_progress_start "Patching config"
if [[ -f /install/.nginx.conf ]]; then
    bash /usr/local/bin/swizzin/nginx/requestrr.sh
    systemctl -q reload nginx
else
    cat > /opt/requestrr/appsettings.json << SET
{
  "Logging": {
    "LogLevel": {
      "Default": "None"
    }
  },
  "AllowedHosts": "*"
}
SET
fi
echo_progress_done "Config patched"

echo_progress_start "Restarting services"
systemctl daemon-reload
systemctl -q enable --now requestrr
echo_progress_done "Services restarted."
echo_success "Requestrr upgraded"
