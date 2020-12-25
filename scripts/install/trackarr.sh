#!/bin/bash

#Trackarr installer

_install() {
    #todo get link dynamically
    case $(_os_arch) in
        "amd64")
            dlurl="https://gitlab.com/cloudb0x/trackarr/uploads/3495407ca9cf1297c37f0a9a0680516b/trackarr_v1.8.2_linux_amd64.tar.gz"
            ;;
        "arm64")
            dlurl="https://gitlab.com/cloudb0x/trackarr/uploads/87dfc6adf8747cfb9a086af4071d67f2/trackarr_v1.8.2_linux_arm64.tar.gz"
            ;;
        "arm")
            dlurl="https://gitlab.com/cloudb0x/trackarr/uploads/e07d9c2cc33ce1371e067945a6bd0f8f/trackarr_v1.8.2_linux_arm.tar.gz"
            ;;
        *)
            echo_error "Arch not supported"
            exit 1
            ;;
    esac

    wget $dlurl -O /tmp/trackarr.tar.gz
    rm -rf /opt/trackarr
    mkdir -p /opt/trackarr
    tar -C /opt/trackarr -xzvf /tmp/trackarr.tar.gz

    useradd --system trackarr -d /opt/trackarr
    chown -R trackarr:trackarr /opt/trackarr
    /opt/trackarr/trackarr
}

_nginx() {
    if [ -f "/install/.nginx.lock" ]; then
        bash /etc/swizzin/scripts/nginx/trackarr.sh
        systemctl reload nginx
    fi
}

_arrconf() {
    if [[ -e /install/.sonarr.lock ]] || [[ -e /install/.sonarrv3.lock ]] || [[ -e /install/.radarr.lock ]] || [[ -e /install/.lidarr.lock ]]; then
        echo_progress_start "Adding arrs to the trackarr config"
        touch /opt/trackarr/pvr.yaml
        echo "pvr:" > /opt/trackarr/pvr.yaml
        if [ -f /install/.sonarr.lock ]; then
            #TDOD check path
            apikey=$(grep -oPm1 "(?<=<ApiKey>)[^<]+" /home/"$user"/.config/NzbDrone/config.xml)
            cat >> /opt/trackarr/pvr.yaml << EOF
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
            cat >> /opt/trackarr/pvr.yaml << EOF
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
            cat >> /opt/trackarr/pvr.yaml << EOF
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
            cat >> /opt/trackarr/pvr.yaml << EOF
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

_install
# _nginx
_arrconf

touch /install/.trackarr.lock
echo_success "Trakarr installed"
