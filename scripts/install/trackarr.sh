#!/bin/bash

#Trackarr installer

_install() {
    #todo get link dynamically
    dlurl="https://gitlab.com/cloudb0x/trackarr/uploads/c02643dedb5dfc19fceae8ebf3c254c8/trackarr_v1.8.1_linux_amd64.tar.gz"
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

    fi
    echo_progress_done "Arrs added"
}

_install
# _nginx
_arrconf
