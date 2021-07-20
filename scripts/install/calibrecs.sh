#!/usr/bin/env bash

if [[ ! -f /install/.calibre.lock ]]; then
    echo_error "Calibre Content server requires calibre. Please run \`box install calibre\` first."
    exit 1
fi

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [ -z "$CALIBRE_LIBRARY_USER" ]; then
    if ! CALIBRE_LIBRARY_USER="$(swizdb get calibre/library_user)"; then
        CALIBRE_LIBRARY_USER=$(_get_master_username)
        swizdb set "calibre/library_user" "$CALIBRE_LIBRARY_USER"
    fi
else
    echo_info "Setting calibre/library_user = $CALIBRE_LIBRARY_USER"
    swizdb set "calibre/library_user" "$CALIBRE_LIBRARY_USER"
fi

if [ -z "$CALIBRE_LIBRARY_PATH" ]; then
    if ! CALIBRE_LIBRARY_PATH="$(swizdb get calibre/library_path)"; then
        CALIBRE_LIBRARY_PATH="/home/$CALIBRE_LIBRARY_USER/Calibre Library"
        swizdb set "calibre/library_path" "$CALIBRE_LIBRARY_PATH"
    fi
else
    echo_info "Setting calibre/library_path = $CALIBRE_LIBRARY_PATH"
    swizdb set "calibre/library_path" "$CALIBRE_LIBRARY_PATH"
fi

clbServerPath="/home/$CALIBRE_LIBRARY_USER/.config/calibrecs"

_adduser() {
    echo_progress_start "Adding users to calibre content server"
    for user in "${users[@]}"; do
        echo_log_only "Adding user $user"
        pass=$(_get_user_password "$user")
        echo -e "1\n$user\n$pass\n$pass" | calibre-server --userdb "$clbServerPath"/server-users.sqlite --manage-users || {
            echo_error "Adding $user to calibre server failed."
            exit 1
        }
    done
    echo_progress_done "Users added to calibre content server"

    chown -R "$CALIBRE_LIBRARY_USER": "$clbServerPath"
}

_systemd() {
    cat > /etc/systemd/system/calibrecs.service << CALICS
[Unit]
Description=calibre content server
After=network.target

[Service]
Type=simple
User=$CALIBRE_LIBRARY_USER
Group=$CALIBRE_LIBRARY_USER
ExecStart=/usr/bin/calibre-server --max-opds-items=30 --max-opds-ungrouped-items=100 --port 8089 "${CALIBRE_LIBRARY_PATH:=CALIBRE_LIBRARY_PATH_GOES_HERE}"


[Install]
WantedBy=multi-user.target
    
CALICS
    # ExecStart=/usr/bin/calibre-server --max-opds-items=30 --max-opds-ungrouped-items=100 --port 8089 --log="/home/$CALIBRE_LIBRARY_USER/.config/calibrecs/.calibre.log" --enable-auth --userdb="/home/$CALIBRE_LIBRARY_USER/.config/calibre/server-users.sqlite" "${CALIBRE_LIBRARY_PATH:=CALIBRE_LIBRARY_PATH_GOES_HERE}"
    echo_progress_done "Calibre content server installed"
    echo_info "The Calibre content server will run on port 8089, please make note of this in case you want to use it in automation"
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/calibrecs.sh
        systemctl reload nginx
        echo_progress_done "nginx configured"
    fi

    if [[ "$CALIBRE_LIBRARY_SKIP" = "true" ]]; then
        echo_info "Please modify /etc/systemd/system/calibrecs.service to point to your library accordingly later."
        return
    fi

}

# adduser function is disabled as currently not all arches support this.
# When arm64 is built from source or it is handled in the installer, this should be revisited
if [[ -n $1 ]]; then
    # users=("$1")
    # _adduser
    exit 0
fi

# readarray -t users < <(_get_user_list)
# _adduser
_systemd
_nginx

echo_progress_start "Enabling Calibre Content Server"
systemctl enable --now -q calibrecs
echo_progress_done "Calibre CS enabled"

echo_success "Calibre content server installed"

touch /install/.calibrecs.lock
