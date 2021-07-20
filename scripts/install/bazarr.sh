#!/bin/bash
# Bazarr installation
# Author: liara
# Copyright (C) 2019 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

codename=$(lsb_release -cs)
_install() {

    user=$(cut -d: -f1 < /root/.master.info)
    if [[ $codename =~ ("bionic"|"stretch") ]]; then
        #shellcheck source=sources/functions/pyenv
        . /etc/swizzin/sources/functions/pyenv
        pyenv_install
        pyenv_install_version 3.7.7
        pyenv_create_venv 3.7.7 /opt/.venv/bazarr
        chown -R "${user}": /opt/.venv/bazarr
    else
        apt_install python3-pip python3-dev python3-venv
        mkdir -p /opt/.venv/bazarr
        python3 -m venv /opt/.venv/bazarr
        chown -R "${user}": /opt/.venv/bazarr
    fi

    if [[ $(_os_arch) =~ "arm" ]]; then
        apt_install libxml2-dev libxslt1-dev python3-libxml2 python3-lxml unrar-free ffmpeg libatlas-base-dev
    fi

    echo_progress_start "Downloading bazarr source"
    wget https://github.com/morpheus65535/bazarr/releases/latest/download/bazarr.zip -O /tmp/bazarr.zip >> $log 2>&1 || {
        echo_error "Failed to download"
        exit 1
    }
    echo_progress_done "Souce downloaded"

    echo_progress_start "Extracting zip"
    rm -rf /opt/bazarr
    mkdir /opt/bazarr
    unzip /tmp/bazarr.zip -d /opt/bazarr >> $log 2>&1 || {
        echo_error "Failed to extract zip"
        exit 1
    }
    rm /tmp/bazarr.zip
    echo_progress_done "Zip extracted"

    chown -R "${user}": /opt/bazarr

    echo_progress_start "Installing python dependencies"
    sudo -u "${user}" bash -c "/opt/.venv/bazarr/bin/pip3 install -r /opt/bazarr/requirements.txt" >> $log 2>&1 || {
        echo_error "Dependencies failed to install"
        exit 1
    }
    mkdir -p /opt/bazarr/data/config/
    echo_progress_done "Dependencies installed"
}

_config() {
    if [[ -f /install/.sonarr.lock ]]; then
        echo_progress_start "Configuring bazarr to work with sonarr"

        # TODO: Use owner when the updaters are merged
        sonarrConfigFile=/home/${user}/.config/sonarr/config.xml

        if [[ -f ${sonarrConfigFile} ]]; then
            sonarrapi=$(grep -oP "ApiKey>\K[^<]+" "${sonarrConfigFile}")
            sonarrport=$(grep -oP "\<Port>\K[^<]+" "${sonarrConfigFile}")
            sonarrbase=$(grep -oP "UrlBase>\K[^<]+" "${sonarrConfigFile}")
        else
            echo_warn "Sonarr configuration was not found in ${sonarrConfigFile}, configure api key, port and url base manually in bazarr"
            badsonarr="true"
        fi

        cat >> /opt/bazarr/data/config/config.ini << SONC
[sonarr]
apikey = ${sonarrapi} 
full_update = Daily
ip = 127.0.0.1
only_monitored = False
base_url = /${sonarrbase}
ssl = False
port = ${sonarrport}
SONC

        echo_progress_done
    fi

    if [[ -f /install/.radarr.lock ]]; then
        echo_progress_start "Configuring bazarr to work with radarr"

        # TODO: Use owner when the updaters are merged
        radarrConfigFile=/home/${user}/.config/Radarr/config.xml

        if [[ -f ${radarrConfigFile} ]]; then
            radarrapi=$(grep -oP "ApiKey>\K[^<]+" "${radarrConfigFile}")
            radarrport=$(grep -oP "\<Port>\K[^<]+" "${radarrConfigFile}")
            radarrbase=$(grep -oP "UrlBase>\K[^<]+" "${radarrConfigFile}")
        else
            echo_warn "Radarr configuration was not found in ${radarrConfigFile}, configure api key, port and url base manually in bazarr"
            badradarr=true
        fi

        cat >> /opt/bazarr/data/config/config.ini << RADC

[radarr]
apikey = ${radarrapi}
full_update = Daily
ip = 127.0.0.1
only_monitored = False
base_url = /${radarrbase}
ssl = False
port = ${radarrport}
RADC
        echo_progress_done
    fi

    cat >> /opt/bazarr/data/config/config.ini << BAZC
[general]
ip = 0.0.0.0
base_url = /
BAZC

    if [ -f /install/.sonarr.lock ] && [ $badsonarr != "true" ]; then
        echo "use_sonarr = True" >> /opt/bazarr/data/config/config.ini
    else
        echo "use_sonarr = False" >> /opt/bazarr/data/config/config.ini
    fi

    if [ -f /install/.radarr.lock ] && [ $badradarr != "true" ]; then
        echo "use_radarr = True" >> /opt/bazarr/data/config/config.ini
    else
        echo "use_radarr = False" >> /opt/bazarr/data/config/config.ini

    fi
}

_nginx() {

    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        sleep 10
        bash /usr/local/bin/swizzin/nginx/bazarr.sh
        systemctl reload nginx
        echo_progress_done "nginx configured"
        echo_warn "If the bazarr wizard comes up, ensure that baseurl is set to: /bazarr/"
    else
        echo_info "Bazarr will run on port 6767"
    fi
}

_systemd() {
    echo_progress_start "Creating and starting service"
    cat > /etc/systemd/system/bazarr.service << BAZ
[Unit]
Description=Bazarr for ${user}
After=syslog.target network.target

[Service]
WorkingDirectory=/opt/bazarr
User=${user}
Group=${user}
UMask=0002
Restart=on-failure
RestartSec=5
Type=simple
ExecStart=/opt/.venv/bazarr/bin/python3 /opt/bazarr/bazarr.py
WorkingDirectory=/opt/bazarr
KillSignal=SIGINT
TimeoutStopSec=20
SyslogIdentifier=bazarr.${user}

[Install]
WantedBy=multi-user.target
BAZ

    chown -R ${user}: /opt/bazarr

    systemctl enable -q --now bazarr 2>&1 | tee -a $log
    echo_progress_done "Service started"
}

_install
_config
_nginx
_systemd

#curl 'http://127.0.0.1:6767/bazarr/save_wizard' --data 'settings_general_ip=127.0.0.1&settings_general_port=6767&settings_general_baseurl=%2Fbazarr%2F&settings_general_sourcepath=&settings_general_destpath=&settings_general_sourcepath=&settings_general_destpath=&settings_general_sourcepath=&settings_general_destpath=&settings_general_sourcepath=&settings_general_destpath=&settings_general_sourcepath=&settings_general_destpath=&settings_general_sourcepath_movie=&settings_general_destpath_movie=&settings_general_sourcepath_movie=&settings_general_destpath_movie=&settings_general_sourcepath_movie=&settings_general_destpath_movie=&settings_general_sourcepath_movie=&settings_general_destpath_movie=&settings_general_sourcepath_movie=&settings_general_destpath_movie=&settings_subfolder=current&settings_subfolder_custom=&settings_addic7ed_username=&settings_addic7ed_password=&settings_addic7ed_random_agents=on&settings_assrt_token=&settings_betaseries_token=&settings_legendastv_username=&settings_legendastv_password=&settings_napisy24_username=&settings_napisy24_password=&settings_opensubtitles_username=&settings_opensubtitles_password=&settings_subscene_username=&settings_subscene_password=&settings_xsubs_username=&settings_xsubs_password=&settings_subliminal_providers=&settings_subliminal_languages=en&settings_serie_default_forced=False&settings_movie_default_forced=False&settings_sonarr_ip=127.0.0.1&settings_sonarr_port=8989&settings_sonarr_baseurl=%2Fsonarr&settings_sonarr_apikey=${sonarrapi}&settings_radarr_ip=127.0.0.1&settings_radarr_port=7878&settings_radarr_baseurl=%2Fradarr&settings_radarr_apikey=${radarrapi}'

touch /install/.bazarr.lock

echo_success "Bazarr installed"
