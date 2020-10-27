#!/bin/bash
# Scrutiny installer by flying_sausages for Swizzin 2020
# GPLv3 applies

scrutinydir="/opt/scrutiny"
webport=8086

_setup () {
    #Need to make sure it's 7.0+
    #Not sure what debian or old ubuntus have
    apt_install smartmontools

    mkdir -p "${scrutinydir}"/config
    mkdir -p "${scrutinydir}"/web
    mkdir -p "${scrutinydir}"/bin

    useradd --system scrutiny -d "${scrutinydir}"
    usermod -a -G disk scrutiny
}

_install () {

    if [[ $(arch) =~ "_64" ]]; then 
        binversion="amd64"
    else
        echo "Arch not currently supported, exiting"
        exit 1
    fi

    echo "Downloading binaries and extracting source code" | tee -a $log
    dlurl=$(curl -s https://api.github.com/repos/AnalogJ/scrutiny/releases/latest | grep "browser_download_url" | grep web-linux-$binversion | head -1 | cut -d\" -f 4)
    # shellcheck disable=SC2181
    if [[ $? != 0 ]]; then
        echo "Failed to query github" | tee -a $log
        exit 1
    fi
    wget "${dlurl}" -O "${scrutinydir}"/bin/scrutiny-web-linux-$binversion >> $log 2>&1
    chmod +x "${scrutinydir}"/bin/scrutiny-web-linux-$binversion

    dlurl=$(curl -s https://api.github.com/repos/AnalogJ/scrutiny/releases/latest | grep "browser_download_url" | grep web-frontend | head -1 | cut -d\" -f 4)
    # shellcheck disable=SC2181
    if [[ $? != 0 ]]; then
        echo "Failed to query github" | tee -a $log
        exit 1
    fi
    wget "${dlurl}" -O /tmp/scrutiny-web-frontend.tar.gz >> $log 2>&1

    tar xvzf /tmp/scrutiny-web-frontend.tar.gz --strip-components 1 -C "${scrutinydir}"/web >> $log 2>&1
    rm -rf /tmp/scrutiny-web-frontend.tar.gz


    cat > "${scrutinydir}"/config/scrutiny.yaml<<EOF
version: 1

web:
  database:
    # The Scrutiny webapp will create a database for you, however the parent directory must exist.
    location: ${scrutinydir}/config/scrutiny.db
  src:
    frontend:
      # The path to the Scrutiny frontend files (js, css, images) must be specified.
      # We'll populate it with files in the next section
      path: ${scrutinydir}/web
    # backend:
      # basepath: /scrutiny
  listen:
    port: $webport
    host: 0.0.0.0
EOF

    dlurl=$(curl -s https://api.github.com/repos/AnalogJ/scrutiny/releases/latest | grep "browser_download_url" | grep collector-metrics-linux-$binversion | head -1 | cut -d\" -f 4)
    # shellcheck disable=SC2181
    if [[ $? != 0 ]]; then
        echo "Failed to query github" | tee -a $log
        exit 1
    fi
    wget "${dlurl}" -O "${scrutinydir}"/bin/scrutiny-collector-metrics-linux-$binversion >> $log 2>&1

    chmod +x "${scrutinydir}"/bin/scrutiny-collector-metrics-linux-$binversion
    chown -R scrutiny:nogroup /opt/scrutiny
    echo "Files downloaded"
}

_systemd () {
    echo "Installing systemd services"
    cat > /etc/systemd/system/scrutiny-web.service <<SYSD
[Unit]
Description=Scrutiny web frontend
After=network.target

[Service]
User=scrutiny
ExecStart=${scrutinydir}/bin/scrutiny-web-linux-$binversion start --config ${scrutinydir}/config/scrutiny.yaml
Restart=on-abort
TimeoutSec=20

[Install]
WantedBy=multi-user.target
SYSD

    cat > /etc/systemd/system/scrutiny-collector.service <<EOF
[Unit]
Description=Runs scrutiny collector
Wants=scrutiny-collector.timer

[Service]
ExecStart=${scrutinydir}/bin/scrutiny-collector-metrics-linux-$binversion run --api-endpoint "http://localhost:$webport"
WorkingDirectory=${scrutinydir}
# Slice=shoes-scraper.slice

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/scrutiny-collector.timer<<EOF
[Unit] 
Description=Run scrutiny-collector every 5 minutes
Requires=scrutiny-collector.service
[Timer]
Unit=scrutiny-collector.service
OnUnitInactiveSec=5min
# RandomizedDelaySec=15min
AccuracySec=1s
[Install]
WantedBy=timers.target
EOF

    systemctl daemon-reload
    systemctl enable --now -q scrutiny-web

    # One run for good measure
    sleep 5
    ${scrutinydir}/bin/scrutiny-collector-metrics-linux-$binversion run --api-endpoint "http://localhost:$webport" >> $log 2>&1

    systemctl enable --now -q scrutiny-collector.timer
    systemctl enable --now -q scrutiny-collector.service
    echo "Scrutiny services started"
}

_nginx () {
    if [[ -f /install/.nginx.lock ]]; then
        echo "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/scrutiny.sh
        systemctl reload nginx
        echo "Nginx configured"
    fi
}

_setup
_install
_systemd
_nginx

touch /install/.scrutiny.lock
echo "Scrutiny installed"

