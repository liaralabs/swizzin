#!/bin/bash

app_name="readarr"

if ! READARR_OWNER="$(swizdb get $app_name/owner)"; then
    READARR_OWNER=$(_get_master_username)
fi

user="$READARR_OWNER"
app_configdir="/home/$user/.config/${app_name^}"
app_servicefile="${app_name}.service"
app_dir="/opt/${app_name^}"
app_lockname="$app_name"

if ask "Would you like to purge the configuration?" Y; then
    purgeapp="True"
else
    purgeapp="False"
fi

systemctl disable --now -q "$app_servicefile"
rm /etc/systemd/system/"$app_servicefile"
systemctl daemon-reload -q
rm -rf "$app_dir"

if [[ "$purgeapp" = "True" ]]; then
    rm -rf "$app_configdir"
fi

if [[ -f /install/.nginx.lock ]]; then
    rm "/etc/nginx/apps/$app_name.conf"
    systemctl reload nginx >> "$log" 2>&1
fi

swizdb clear "$app_name/owner"
rm "/install/.$app_lockname.lock"
