#!/bin/bash
# Flying Sausages 2020 for swizzin
#calibreweb installer

calibrewebdir="/opt/calibreweb"
clbWebUser="calibreweb" # or make this master user?

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [ -z "$CALIBRE_LIBRARY_USER" ]; then
    if ! CALIBRE_LIBRARY_USER="$(swizdb get calibre/library_user)"; then
        CALIBRE_LIBRARY_USER=$(_get_master_username)
        swizdb set "calibre/library_user" "$CALIBRE_LIBRARY_USER"
    fi
else
    echo_info "Setting calibre/library_user = $CALIBRE_LIBRARY_USER"
    swizdb set "calibre/library_user" "$CALIBRE_LIBRARY_USER"
fi

if [ -z "$CALIBRE_LIBRARY_PATH" ]; then
    if ! CALIBRE_LIBRARY_PATH="$(swizdb get calibre/library_path)"; then
        CALIBRE_LIBRARY_PATH="/home/$CALIBRE_LIBRARY_USER/Calibre Library"
        swizdb set "calibre/library_path" "$CALIBRE_LIBRARY_PATH"
    fi
else
    echo_info "Setting calibre/library_path = $CALIBRE_LIBRARY_PATH"
    swizdb set "calibre/library_path" "$CALIBRE_LIBRARY_PATH"
fi

if [[ ! -f /install/.calibre.lock ]]; then    # If it's not installed from swizzin
    if [ ! -e "$CALIBRE_LIBRARY_PATH" ]; then # If the default location does not exist OR the variable is not set...
        echo_warn "Calibre not installed, and no alternative library path is specified."
        echo_info "While having a calibre library is functionally required to use calibreweb, the calibreweb installer will not fail without it. You can create a calibre library at a later stage."
        if ask "Install Calibre through swizzin now?" Y; then
            bash /etc/swizzin/scripts/install/calibre.sh || {
                echo_info "Installer failed, please try again"
                exit 1
            }
        fi
    fi
fi

function _install_dependencies_calibreweb() {
    apt_install unzip imagemagick
}

function _install_calibreweb() {
    echo_progress_start "Creating venv for calibreweb"
    apt_install python3-pip python3-dev python3-venv
    mkdir -p /opt/.venv/calibreweb
    python3 -m venv /opt/.venv/calibreweb
    echo_progress_done "Venv created"

    echo_progress_start "Downloading calibreweb source code archive"
    dlurl=$(curl -s https://api.github.com/repos/janeczku/calibre-web/releases/latest | jq -r '.zipball_url') || {
        echo_error "Failed to query github"
        exit 1
    }

    wget -q "${dlurl}" -O /tmp/calibreweb.zip >> $log 2>&1 || {
        echo_error "Failed to download source code"
        exit 1
    }

    echo_progress_done

    echo_progress_start "Extracting archive"
    unzip /tmp/calibreweb.zip -d /tmp/calibrewebdir >> $log 2>&1
    subdir=$(ls /tmp/calibrewebdir)
    mv /tmp/calibrewebdir/"$subdir" $calibrewebdir
    echo_progress_done

    echo_progress_start "Creating users and setting permissions"
    useradd $clbWebUser --system -d "$calibrewebdir" >> $log 2>&1
    chown -R $clbWebUser:$clbWebUser $calibrewebdir
    chown -R ${clbWebUser}: /opt/.venv/calibreweb
    #This bit right here will ensure that the system user created will have access to the master user's folders where he might have the CalibreDB
    usermod -a -G "${CALIBRE_LIBRARY_USER}" $clbWebUser >> $log 2>&1
    echo_progress_done

    echo_progress_start "Installing python dependencies"
    sudo -u ${clbWebUser} bash -c "/opt/.venv/calibreweb/bin/pip3 install -r $calibrewebdir/requirements.txt" >> $log 2>&1
    #fuck ldap. all my homies hate ldap
    sed '/ldap/Id' -i $calibrewebdir/optional-requirements.txt
    sudo -u ${clbWebUser} bash -c "/opt/.venv/calibreweb/bin/pip3 install -r $calibrewebdir/optional-requirements.txt" >> $log 2>&1
    echo_progress_done
}

_install_kepubify() {
    echo_progress_start "Installing kepubify"
    wget -q "https://github.com/pgaskin/kepubify/releases/download/v3.1.2/kepubify-linux-64bit" -O /tmp/kepubify >> $log 2>&1
    chmod a+x /tmp/kepubify
    mv /tmp/kepubify /usr/local/bin/kepubify
    #TODO and figure out if it's needed for all cases or not
    echo_progress_done
}

_nginx_calibreweb() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Setting up nginx conf"
        bash /etc/swizzin/scripts/nginx/calibreweb.sh
        systemctl reload nginx
        echo_progress_done
    else
        echo_info "calibreweb will be accessible on port 8083"
    fi
}

_systemd_calibreweb() {
    echo_progress_start "Creating and enabling systemd services"
    cat > /etc/systemd/system/calibreweb.service << EOF
[Unit]
Description=calibreweb

[Service]
User=$clbWebUser
Type=simple
ExecStart=/opt/.venv/calibreweb/bin/python3 $calibrewebdir/cps.py -f
WorkingDirectory=$calibrewebdir
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/opt/.venv/calibreweb/bin

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload -q 2>&1 | tee -a $log
    systemctl enable -q --now calibreweb.service 2>&1 | tee -a $log
    echo_progress_done
}

_post_libdir() {
    if [[ ! -e "$CALIBRE_LIBRARY_PATH" ]]; then
        echo_warn "Calibre library path either not set, or path does not exist. Please configure your calibre library manually in the web interface"
        return 1
    fi

    echo_progress_start "Setting Library to $CALIBRE_LIBRARY_PATH"

    timeout 25 bash -c 'while [[ "$(curl -q -L --insecure -s -o /dev/null -w ''%{http_code}'' http://127.0.0.1:8083)" != "200" ]]; do sleep 1; echo_log_only "waiting on calibreweb to come up..."; done' || {
        echo_log_only "Timed out"
        return 1
    }
    curl -s -k 'http://127.0.0.1:8083/basicconfig' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' --compressed -H 'Content-Type: application/x-www-form-urlencoded' -H 'Connection: keep-alive' \
        --data-urlencode "config_calibre_dir=$CALIBRE_LIBRARY_PATH" \
        --data-urlencode "submit=" >> "$log" || {
        echo_log_only "curl fucked"
        return 1
    }
    echo_progress_done "Library set"
}

_post_changepass() {
    sleep 5
    pass="$(_get_user_password "$CALIBRE_LIBRARY_USER")"
    /opt/.venv/calibreweb/bin/python3 /opt/calibreweb/cps.py -s admin:"${pass}" >> "$log" 2>&1 || {
        echo_info "Could not change password, please use admin:admin123 to log in and change credentials immediately."
        return 1
    }
    echo_info "Please use the username \"admin\" (literally that, NOT your master username) and the password of $CALIBRE_LIBRARY_USER to log in to calibreweb"
}

_install_dependencies_calibreweb
_install_calibreweb
_install_kepubify
_systemd_calibreweb
_nginx_calibreweb
_post_libdir || {
    echo_warn "calibreweb did not start within time, please set Library path manually in web interface"
}
_post_changepass

touch /install/.calibreweb.lock
echo_success "calibreweb installed"
echo_docs "applications/calibreweb#post-install"
