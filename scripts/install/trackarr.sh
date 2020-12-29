#!/bin/bash

#Trackarr installer

pvryaml="/opt/trackarr/pvr.yaml"

_install() {
    #todo get link dynamically
    case $(_os_arch) in
        "amd64") dlurl="https://gitlab.com/cloudb0x/trackarr/uploads/3495407ca9cf1297c37f0a9a0680516b/trackarr_v1.8.2_linux_amd64.tar.gz" ;;
        "arm64") dlurl="https://gitlab.com/cloudb0x/trackarr/uploads/87dfc6adf8747cfb9a086af4071d67f2/trackarr_v1.8.2_linux_arm64.tar.gz" ;;
        "armhf") dlurl="https://gitlab.com/cloudb0x/trackarr/uploads/e07d9c2cc33ce1371e067945a6bd0f8f/trackarr_v1.8.2_linux_arm.tar.gz" ;;
        *)
            echo_error "Arch not supported"
            exit 1
            ;;
    esac
    echo_progress_start "Downloading trackarr and extracting"

    if ! wget $dlurl -O /tmp/trackarr.tar.gz >> $log 2>&1; then
        echo_error "Failed to download"
        exit 1
    fi
    rm -rf /opt/trackarr
    mkdir -p /opt/trackarr
    tar -C /opt/trackarr -xzf /tmp/trackarr.tar.gz >> $log
    echo_progress_done "Trackarr downloaded and extracted"

    useradd --system trackarr -d /opt/trackarr
    chown -R trackarr:trackarr /opt/trackarr
    /opt/trackarr/trackarr >> $log 2>&1
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx for trackarr"
        /etc/swizzin/scripts/nginx/trackarr.sh
        systemctl reload nginx
        echo_progress_done "Nginx configured"
    else
        if ! grep -q "user:" /opt/trackarr/config.yaml; then
            #shellcheck source=sources/functions/utils
            . /etc/swizzin/sources/functions/utils
            user=$(_get_master_username)
            pass=$(_get_user_password "$user")
            sed -i "/^server:*/a \ \ pass: $pass" /opt/trackarr/config.yaml
            sed -i "/^server:*/a \ \ user: $user" /opt/trackarr/config.yaml
        fi
        echo_info "trackarr will be running on port 7337 and protected by your master's credentials"
    fi
}

_arrconf() {
    if [[ -e /install/.sonarr.lock ]] || [[ -e /install/.sonarrv3.lock ]] || [[ -e /install/.radarr.lock ]] || [[ -e /install/.lidarr.lock ]]; then
        echo_progress_start "Adding arrs to the trackarr config"
        touch "$pvryaml"
        echo "pvr:" > "$pvryaml"
        if [ -f /install/.sonarr.lock ]; then
            #TDOD check path
            apikey=$(grep -oPm1 "(?<=<ApiKey>)[^<]+" /home/"$user"/.config/NzbDrone/config.xml)
            cat >> "$pvryaml" << EOF
- name: sonarr
  url: http://127.0.0.1:8989
  apikey: $apikey
  enabled: true
  # filters:
EOF
        fi
        if [ -f /install/.sonarrv3.lock ]; then
            #TDOD check path
            apikey=$(grep -oPm1 "(?<=<ApiKey>)[^<]+" /home/"$user"/.config/sonarr/config.xml)
            cat >> "$pvryaml" << EOF
- name: sonarr
  url: http://127.0.0.1:8989
  apikey: $apikey
  enabled: true
  # filters:
EOF
        fi
        if [ -f /install/.radarr.lock ]; then
            #TDOD check path
            apikey=$(grep -oPm1 "(?<=<ApiKey>)[^<]+" /home/"$user"/.config/Radarr/config.xml)
            cat >> "$pvryaml" << EOF
- name: radarr
  url: http://127.0.0.1:7878
  apikey: $apikey
  enabled: true
  # filters:
EOF
        fi
        if [ -f /install/.lidarr.lock ]; then
            #TDOD check path
            apikey=$(grep -oPm1 "(?<=<ApiKey>)[^<]+" /home/"$user"/.config/Lidarr/config.xml)
            cat >> "$pvryaml" << EOF
- name: lidarr
  url: http://127.0.0.1:8686
  apikey: $apikey
  enabled: true
  # filters:
EOF
        fi
        echo_progress_done "Arrs added"
    fi
}

function _systemd() {
    echo_progress_start "Installing systemd service"
    cat > /etc/systemd/system/trackarr.service << SYSD
# Service file example for Trackarr
[Unit]
Description=Trackarr - an autodl for the modern human
After=network.target

[Service]
User=trackarr
ExecStart=/opt/trackarr/trackarr
Restart=on-failure
TimeoutSec=20

[Install]
WantedBy=multi-user.target
SYSD
    systemctl daemon-reload -q
    systemctl enable -q --now trackarr 2>&1 | tee -a $log
    echo_progress_done "Trackarr started"
}

_install
_nginx
_arrconf
_systemd

touch /install/.trackarr.lock
echo_success "Trakarr installed"
