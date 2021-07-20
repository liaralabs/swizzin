#!/bin/bash

if [[ -f /install/.bazarr.lock ]]; then
    codename=$(lsb_release -cs)
    user=$(cut -d: -f1 < /root/.master.info)
    if ! grep -q .venv /etc/systemd/system/bazarr.service; then
        echo_info "Updating bazarr to python3 virtualenv"
        if [[ $codename =~ ("bionic"|"stretch") ]]; then
            . /etc/swizzin/sources/functions/pyenv
            pyenv_install
            pyenv_install_version 3.7.7
            pyenv_create_venv 3.7.7 /opt/.venv/bazarr
            chown -R ${user}: /opt/.venv/bazarr
        else
            apt_install python3-pip python3-dev python3-venv
            mkdir -p /opt/.venv/bazarr
            python3 -m venv /opt/.venv/bazarr
            chown -R ${user}: /opt/.venv/bazarr
        fi
        mv /home/${user}/bazarr /opt
        sudo -u ${user} bash -c "/opt/.venv/bazarr/bin/pip3 install -r requirements.txt" > /dev/null 2>&1
        sed -i "s|ExecStart=.*|ExecStart=/opt/.venv/bazarr/bin/python3 /opt/bazarr/bazarr.py|g" /etc/systemd/system/bazarr.service
        sed -i "s|WorkingDirectory=.*|WorkingDirectory=/opt/bazarr|g" /etc/systemd/system/bazarr.service
        systemctl daemon-reload
        systemctl try-restart bazarr
    fi

    if ! grep -q numpy <(/opt/.venv/bazarr/bin/pip freeze); then
        sudo -u ${user} bash -c "/opt/.venv/bazarr/bin/pip3 install -r /opt/bazarr/requirements.txt" > /dev/null 2>&1
        systemctl try-restart bazarr
    fi

    # Switching deployment type from git-based to release archive
    if [ -d /opt/bazarr/.git ]; then
        echo_progress_start "Updating bazarr to new structure"
        active=$(systemctl is-active bazarr)
        if [[ $active == "active" ]]; then
            systemctl stop bazarr
        fi

        wget https://github.com/morpheus65535/bazarr/releases/latest/download/bazarr.zip -O /tmp/bazarr.zip >> $log 2>&1 || {
            echo_error "Failed to download"
            exit 1
        }

        cp -R /opt/bazarr/data /tmp/bazarr_data
        mv /opt/bazarr/ /tmp/bazarr-bak

        mkdir /opt/bazarr
        unzip /tmp/bazarr.zip -d /opt/bazarr >> $log 2>&1 || {
            echo_error "Failed to extract zip"
            mv /tmp/bazarr-bak /opt/bazarr/
            exit 1
        }
        rm /tmp/bazarr.zip

        sudo -u "${user}" bash -c "/opt/.venv/bazarr/bin/pip3 install -r /opt/bazarr/requirements.txt" >> $log 2>&1 || {
            echo_error "Dependencies failed to install"
            exit 1
        }

        cp -R /tmp/bazarr_data /opt/bazarr/data
        chown -R "${user}": /opt/bazarr

        if [[ $active == "active" ]]; then
            systemctl start bazarr
        fi
        echo_progress_done "Bazarr updated"
    fi
fi
