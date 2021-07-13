#!/bin/bash
# radarr v3 installer
# Flying sauasges for swizzin 2020

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [ -z "$RADARR_OWNER" ]; then
    if ! RADARR_OWNER="$(swizdb get radarr/owner)"; then
        RADARR_OWNER=$(_get_master_username)
        echo_log_only "Setting radarr owner = $RADARR_OWNER"
        swizdb set "radarr/owner" "$RADARR_OWNER"
    fi
else
    echo_info "Setting radarr owner = $RADARR_OWNER"
    swizdb set "radarr/owner" "$RADARR_OWNER"
fi

user="$RADARR_OWNER"

_install_radarr() {
    apt_install curl mediainfo sqlite3

    radarrConfDir="/home/$user/.config/Radarr"
    mkdir -p "$radarrConfDir"
    chown -R "$user":"$user" /home/"$user"/.config

    echo_progress_start "Downloading release archive"
    case "$(_os_arch)" in
        "amd64") dlurl="https://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64" ;;
        "armhf") dlurl="https://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=arm" ;;
        "arm64") dlurl="https://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=arm64" ;;
        *)
            echo_error "Arch not supported"
            exit 1
            ;;
    esac

    if ! curl "$dlurl" -L -o /tmp/Radarr.tar.gz >> "$log" 2>&1; then
        echo_error "Download failed, exiting"
        exit 1
    fi
    echo_progress_done "Archive downloaded"

    echo_progress_start "Extracting archive"
    tar -xvf /tmp/Radarr.tar.gz -C /opt >> "$log" 2>&1
    echo_progress_done "Archive extracted"

    touch /install/.radarr.lock

    echo_progress_start "Installing Systemd service"
    cat > /etc/systemd/system/radarr.service << EOF
[Unit]
Description=Radarr Daemon
After=syslog.target network.target

[Service]
# Change the user and group variables here.
User=${user}
Group=${user}

Type=simple

# Change the path to Radarr here if it is in a different location for you.
ExecStart=/opt/Radarr/Radarr -nobrowser -data=/home/$user/.config/Radarr/
TimeoutStopSec=20
KillMode=process
Restart=on-failure

# These lines optionally isolate (sandbox) Radarr from the rest of the system.
# Make sure to add any paths it might use to the list below (space-separated).
#ReadWritePaths=/opt/Radarr /path/to/movies/folder
#ProtectSystem=strict
#PrivateDevices=true
#ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF
    chown -R "$user":"$user" /opt/Radarr
    systemctl -q daemon-reload
    systemctl enable --now -q radarr
    sleep 1
    echo_progress_done "Radarr service installed and enabled"

    if [[ -f $radarrConfDir/update_required ]]; then
        echo_progress_start "Radarr is installing an internal upgrade..."
        # echo "You can track the update by running \`systemctl status radarr\`0. in another shell."
        # echo "In case of errors, please press CTRL+C and run \`box remove radarr\` in this shell and check in with us in the Discord"
        while [[ -f $radarrConfDir/update_required ]]; do
            sleep 1
            echo_log_only "Upgrade file is still here"
        done
        echo_progress_done "Upgrade finished"
    fi

}

_nginx_radarr() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Installing nginx configuration"
        #TODO what is this sleep here for? See if this can be fixed by doing a check for whatever it needs to
        sleep 10
        bash /usr/local/bin/swizzin/nginx/radarr.sh
        systemctl -q reload nginx
        echo_progress_done "Nginx configured"
    else
        echo_info "Radarr will be available on port 7878. Secure your installation manually through the web interface."
    fi
}

_install_radarr
_nginx_radarr

if [[ -f /install/.ombi.lock ]]; then
    echo_info "Please adjust your Ombi setup accordingly"
fi

if [[ -f /install/.tautulli.lock ]]; then
    echo_info "Please adjust your Tautulli setup accordingly"
fi

if [[ -f /install/.bazarr.lock ]]; then
    echo_info "Please adjust your Bazarr setup accordingly"
fi

echo_success "Radarr installed"
