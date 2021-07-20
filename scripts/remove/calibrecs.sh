#!/usr/bin/env bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [ -z "$CALIBRE_LIBRARY_USER" ]; then
    if ! CALIBRE_LIBRARY_USER="$(swizdb get calibre/library_user)"; then
        CALIBRE_LIBRARY_USER=$(_get_master_username)
    fi
fi

# if [ -z "$CALIBRE_LIBRARY_PATH" ]; then
#     if ! CALIBRE_LIBRARY_USER="$(swizdb get calibre/library_path)"; then
#         CALIBRE_LIBRARY_PATH="/home/$CALIBRE_LIBRARY_USER/Calibre Library"
#         swizdb set "calibre/library_path" "$CALIBRE_LIBRARY_USER"
#     fi
# fi

systemctl disable --now -q calibrecs
rm /etc/systemd/system/calibrecs.service

rm -rf /home/"$CALIBRE_LIBRARY_USER"/.config/calibrecs

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/calibrecs.conf
    systemctl reload nginx
fi

if [ ! -f /install/.calibreweb.lock ] && [ ! -f /install/.calibre.lock ]; then
    echo_log_only "Clearing calibre swizdb"
    swizdb clear calibre/library_path
    swizdb clear calibre/library_user
fi

rm /install/.calibrecs.lock
