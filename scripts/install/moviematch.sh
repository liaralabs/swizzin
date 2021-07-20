#!/bin/bash
_queries() {
    if [ -z "$PLEX_SERVER" ]; then
        if [[ ! -f /install/.plex.lock ]]; then
            echo_warn "Plex server not installed"
            echo_query "Please enter your Plex Server's address (e.g. domain.ltd:32400)"
            read -r PLEX_SERVER
        else
            PLEX_SERVER="localhost:32400"
        fi
    else
        echo_info "Environment variable PLEX_SERVER set to $PLEX_SERVER"
    fi

    if [ -z "$PLEX_TOKEN" ]; then
        echo_info "Moviematch needs to connect to Plex via a Token. You can hear how to retrieve one here:\nhttps://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/"
        echo_query "Please enter your Plex Token"
        read -r PLEX_TOKEN
    else
        echo_info "Environment variable PLEX_TOKEN set to $PLEX_TOKEN"
    fi
}

mmatchDir="/opt/moviematch"

_install_moviematch() {

    useradd moviematch --system -md "$mmatchDir" >> $log 2>&1

    echo_progress_start "Downloading moviematch"
    # git clone https://github.com/LukeChannings/moviematch.git $mmatchDir >> $log
    case "$(_os_arch)" in
        amd64 | arm64)
            dlurl="https://github.com/LukeChannings/moviematch/releases/download/v2.0.0-alpha.7/linux-$(_os_arch).zip"
            ;;
        *)
            echo "Arch not supported"
            exit 1
            ;;
    esac

    wget "$dlurl" -O /tmp/moviematch.zip -q || {
        echo "Failed to download binary"
        exit 1
    }

    unzip /tmp/moviematch.zip -d "$mmatchDir" >> $log 2>&1 || {
        echo "failed to unzip archive"
        exit 1
    }

    chmod +x $mmatchDir/moviematch
    chmod o+rx -R $mmatchDir

    sudo chown -R moviematch:moviematch $mmatchDir

    echo_progress_done "Binary downloaded and extracted"

    cat > $mmatchDir/config.yaml << ENV
port: 8420
servers:
  - url: http://$PLEX_SERVER
    token: $PLEX_TOKEN
ENV
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/moviematch.sh
        systemctl reload nginx
        echo_progress_done "nginx configured"
    else
        echo_info "Moviematch is available on port 8420"
    fi
}

_systemd() {

    echo_progress_start "Installing systemd service and starting moviematch"
    cat > /etc/systemd/system/moviematch.service << SYSTEMD
[Unit]
Description=Moviematch
Documentation=https://swizzin.ltd/applications/moviematch
After=network.target

[Service]
Type=simple
User=moviematch
WorkingDirectory=${mmatchDir}
ExecStart=${mmatchDir}/moviematch
Restart=on-failure

[Install]
WantedBy=multi-user.target
SYSTEMD
    systemctl daemon-reload
    systemctl enable --now -q moviematch
}

_queries
_install_moviematch
_nginx
_systemd

touch /install/.moviematch.lock
echo_success "Moviematch installed"
# deno run --allow-net --allow-read --allow-env $mmatchDir/src/index.ts
