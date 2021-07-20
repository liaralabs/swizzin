#!/bin/bash
if [[ -f /install/.radarr.lock ]]; then
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/radarr

    #Move radarr installs to v3.net
    if grep -q "ExecStart=/usr/bin/mono" /etc/systemd/system/radarr.service; then
        echo_info "Moving Radarr from mono to .Net"
        #shellcheck source=sources/functions/utils
        . /etc/swizzin/sources/functions/utils
        [[ -z $RADARR_OWNER ]] && RADARR_OWNER=$(_get_master_username)

        if [[ $(_radarr_version) = "mono-v3" ]]; then
            echo_progress_start "Downloading release files"
            urlbase="https://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore"
            case "$(_os_arch)" in
                "amd64") dlurl="${urlbase}&arch=x64" ;;
                "armhf") dlurl="${urlbase}&arch=arm" ;;
                "arm64") dlurl="${urlbase}&arch=arm64" ;;
                *)
                    echo_error "Arch not supported"
                    exit 1
                    ;;
            esac
            if ! curl "$dlurl" -L -o /tmp/radarr.tar.gz >> "$log" 2>&1; then
                echo_error "Download failed, exiting"
                exit 1
            fi
            echo_progress_done "Release downloaded"

            isactive=$(systemctl is-active radarr)
            echo_log_only "Radarr was $isactive"
            [[ $isactive == "active" ]] && systemctl stop radarr -q

            echo_progress_start "Removing old binaries"
            rm -rf /opt/Radarr/
            echo_progress_done "Binaries removed"

            echo_progress_start "Extracting archive"
            tar -xvf /tmp/Radarr.tar.gz -C /opt >> "$log" 2>&1
            chown -R "$RADARR_OWNER":"$RADARR_OWNER" /opt/Radarr
            echo_progress_done "Archive extracted"

            echo_progress_start "Fixing Radarr systemd service"
            # Watch out! If this sed runs, the updater will not trigger anymore. keep this at the bottom.
            sed -i "s|ExecStart=/usr/bin/mono /opt/Radarr/Radarr.exe|ExecStart=/opt/Radarr/Radarr|g" /etc/systemd/system/radarr.service
            systemctl daemon-reload
            [[ $isactive == "active" ]] && systemctl start radarr -q
            echo_progress_done "Service fixed and restarted"
            echo_success "Radarr upgraded to .Net"

            if [[ -f /install/.nginx.lock ]]; then
                echo_progress_start "Upgrading nginx config for Radarr"
                bash /etc/swizzin/scripts/nginx/radarr.sh
                systemctl reload nginx -q
                echo_progress_done "Nginx conf for Radarr upgraded"
            fi

        elif [[ $(_radarr_version) = "mono-v2" ]]; then
            echo_warn "Radarr v0.2 is EOL and not supported. Please upgrade your radarr to v3. An attempt will be made to migrate to .Net core on the next \`box update\` run"
            echo_docs "applications/radarr#migrating-to-v3-on-net-core"
        fi
    else
        echo_log_only "Radarr's service is not pointing to mono"
    fi

    # Ensure the radarr owner is recorded
    if [ -z "$RADARR_OWNER" ]; then
        if ! RADARR_OWNER="$(swizdb get radarr/owner)"; then
            master=$(_get_master_username)
            if [ ! -d /home/"$master"/.config/Radarr ]; then
                echo_error "Config dir /home/$RADARR_OWNER/.config/Radarr does not exist.\nPlease export the \"RADARR_OWNER\" as described below, and run \`box update\` again."
                echo_docs "applications/radarr#optional-parameters"
                # Stop the box updater because who knows what could rely on this in the future
                exit 1
            fi
            RADARR_OWNER="$master"
            echo_info "Setting Radarr owner = $RADARR_OWNER"
            swizdb set "radarr/owner" "$RADARR_OWNER"
        fi
    else
        if [ ! -d /home/"$RADARR_OWNER"/.config/Radarr ]; then
            echo_error "Config dir /home/$RADARR_OWNER/.config/Radarr does not exist."
            # Stop the box updater because who knows what could rely on this in the future
            exit 1
        fi
        echo_info "Setting Radarr owner = $RADARR_OWNER"
        swizdb set "radarr/owner" "$RADARR_OWNER"
    fi

    app_configfile="/home/${RADARR_OWNER}/.config/Radarr/config.xml"

    #Mandatory SSL Port change for Readarr
    if grep -q "<SslPort>8787" "$app_configfile"; then
        echo_progress_start "Changing Radarr's default SSL port"
        sed -i 's|<SslPort>8787</SslPort>|<SslPort>9898</SslPort>|g' "$app_configfile"
        systemctl try-restart -q radarr

        if grep -q "<EnableSsl>True" "$app_configfile"; then
            echo_info "Radarr SSL port changed from 8787 to 9898 due to Readarr conflicts; please ensure to adjust your dependent systems in case they were using this port"
        fi
        echo_progress_done "Radarr's default SSL port changed"
    else
        echo_log_only "Radarr's ports are not on 8787"
    fi

fi
