#!/usr/bin/env bash

# Overseer installer by flying sausages 2020 GPLv3

_dependencies() {
    apt_install libsqlite3-dev sqlite3

    #shellcheck source=sources/functions/npm
    . /etc/swizzin/sources/functions/npm
    npm_install #Install node 12 LTS and npm if they're not present or outdated

    echo_progress_start "Installing yarn"
    npm install -g yarn >> "$log" 2>&1 || {
        echo_error "Yarn failed to install"
        exit 1
    }
    echo_progress_done "Yarn installed"
}

_user() {
    mkdir /opt/overseerr
    useradd overseerr --system -d /opt/overseerr
    chown -R overseerr: /opt/overseerr
}

_service() {
    # Adapted from https://aur.archlinux.org/cgit/aur.git/tree/overseerr.service?h=overseerr
    cat > /etc/systemd/system/overseerr.service << EOF
[Unit]
Description=Overseerr Service
Wants=network-online.target
After=network-online.target

[Service]
EnvironmentFile=/opt/overseerr/env.conf
Environment=NODE_ENV=production
User=overseerr
Group=overseerr
Type=exec
Restart=on-failure
WorkingDirectory=/opt/overseerr
ExecStart=/usr/bin/node dist/index.js

[Install]
WantedBy=multi-user.target
EOF

    cat > /opt/overseerr/env.conf << EOF
# specify on which port to listen
PORT=5055
EOF

    systemctl daemon-reload
    systemctl enable --now -q overseerr
}

_nginx() {
    if [ -f "/install/.nginx.lock" ]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/overseerr.sh
        systemctl reload nginx
        echo_progress_done "Nginx configured"
    else
        echo_info "Overseerr will be available on port 5055"
    fi
}

_dependencies
_user
#shellcheck source=sources/functions/overseerr
. /etc/swizzin/sources/functions/overseerr
overseerr_install
_service
# _nginx

touch /install/.overseerr.lock
