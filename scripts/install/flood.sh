#!/bin/bash
# Flood for rtorrent installation script for swizzin
# Author: liara

_install() {

    #shellcheck source=sources/functions/npm
    . /etc/swizzin/sources/functions/npm
    npm_install

    sudo useradd --create-home --shell /bin/false flood -d /opt/flood
    echo_progress_start "Installing flood"
    npm install --global flood >> "$log" 2>&1
    echo_progress_done "Flood installed"

}

_systemd() {
    cat > /etc/systemd/system/flood.service << EOF
[Unit]
Description=Flood Web UI
After=network.target

[Service]
WorkingDirectory=~
ExecStart=/usr/bin/flood -p 3006
User=flood

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable flood --now -q
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/flood.sh
        systemctl reload nginx
        echo_progress_done "nginx configured"
    else
        sed '/ExecStart=/ s/$/ --host=0.0.0.0' -i /etc/systemd/system/flood.service
        echo_info "Flood will run on port 3006"
    fi
}

_permissions() {
    usermod -a -G "$user" flood
    # TODO check socket permissions again
}

if [[ -n $1 ]]; then
    echo_progress_start "Giving flood permissions to $user dir"
    user=$1
    _permissions
    echo_progress_done "Done"
    echo_info "Please create the flood account for $user manually"
    exit 0
fi

_install
_systemd
_nginx
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    echo_progress_start "Giving flood permissions to $user dir"
    _permissions
    echo_progress_done "Done"
    echo_info "Please create the flood account for $user manually"
done

echo_success "Flood installed"
echo_info "Please finish the setup of flood in the browser"
touch /install/.flood.lock
