#!/bin/bash
# Sonarr v3 installer
# Flying sauasges for swizzin 2020

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

[[ -z $SONARR_OLD_OWNER ]] && SONARR_OLD_OWNER=$(_get_master_username)

if [ -z "$SONARR_OWNER" ]; then
    if ! SONARR_OWNER="$(swizdb get sonarr/owner)"; then
        SONARR_OWNER=$(_get_master_username)
        echo_log_only "Setting sonarr owner = $SONARR_OWNER"
        swizdb set "sonarr/owner" "$SONARR_OWNER"
    fi
else
    echo_info "Setting sonarr owner = $SONARR_OWNER"
    swizdb set "sonarr/owner" "$SONARR_OWNER"
fi

user="$SONARR_OWNER"
sonarrv3confdir="/home/$user/.config/sonarr"

#Handles existing v2 instances
_sonarrold_flow() {
    v2present=false
    if [[ -f /install/.sonarrold.lock ]]; then
        v2present=true
    fi
    if dpkg -l | grep nzbdrone > /dev/null 2>&1; then
        v2present=true
    fi

    if [[ $v2present == "true" ]]; then
        echo_warn "Sonarr v2 is detected. Continuing will migrate your current v2 installation. This will stop and remove sonarr v2 You can read more about the migration at https://swizzin.ltd/applications/sonarrv3#migrating-from-v2. An additional copy of the backup will be made into /root/swizzin/backups/sonarrold.bak/"
        if ! ask "Do you want to continue?" N; then
            exit 0
        fi

        if ask "Would you like to trigger a Sonarr-side backup?" Y; then
            echo_progress_start "Backing up Sonarr v2"
            if [[ -f /install/.nginx.lock ]]; then
                address="http://127.0.0.1:8989/sonarr/api"
            else
                address="http://127.0.0.1:8989/api"
            fi

            [[ -z $SONARR_OLD_OWNER ]] && SONARR_OLD_OWNER=$(_get_master_username)
            if [[ ! -d /home/"${SONARR_OLD_OWNER}"/.config/NzbDrone ]]; then
                echo_error "No Sonarr config folder found for $SONARR_OLD_OWNER. Exiting"
                exit 1
            fi

            apikey=$(awk -F '[<>]' '/ApiKey/{print $3}' /home/"${SONARR_OLD_OWNER}"/.config/NzbDrone/config.xml)
            echo_log_only "apikey = $apikey"

            #This starts a backup on the current Sonarr instance. The logic below waits until the query returns as "completed"
            response=$(curl -sd '{name: "backup"}' -H "Content-Type: application/json" -X POST ${address}/command?apikey="${apikey}" --insecure)
            echo_log_only "$response"
            id=$(echo "$response" | jq '.id')
            echo_log_only "id=$id"

            if [[ -z $id ]]; then
                echo_warn "Failure triggering backup (see logs). Current Sonarr config and previous weekly backups will be backed up up and copied for migration"
                if ! ask "Continue without triggering internal Sonarr backup?" N; then
                    exit 1
                fi
            else
                echo_log_only "Sonarr backup Job ID = $id, waiting to finish"

                status=""
                counter=0
                while [[ $status =~ ^(queued|started|)$ ]]; do
                    sleep 0.2
                    status=$(curl -s "${address}/command/$id?apikey=${apikey}" --insecure | jq -r '.status')
                    ((counter += 1))
                    if [[ $counter -gt 100 ]]; then
                        echo_error "Sonarr backup timed out (20s), cancelling installation."
                        exit 1
                    fi
                done
                if [[ $status = "completed" ]]; then
                    echo_progress_done "Backup complete"
                else
                    echo_error "Sonarr returned unexpected status ($status). Terminating. Please try again."
                    exit 1
                fi
            fi
        fi

        mkdir -p /root/swizzin/backups/
        echo_progress_start "Copying files to a backup location"
        cp -R /home/"${SONARR_OLD_OWNER}"/.config/NzbDrone /root/swizzin/backups/sonarrold.bak
        echo_progress_done "Backups copied"

        if [[ -d /home/"${user}"/.config/sonarr ]]; then
            if ask "$user already has a sonarrv3 directory. Overwrite?" Y; then
                rm -rf
                cp -R /home/"${SONARR_OLD_OWNER}"/.config/NzbDrone /home/"${user}"/.config/sonarr
            else
                echo_info "Leaving v3 dir as is, why did we do any of this..."
            fi
        else
            cp -R /home/"${SONARR_OLD_OWNER}"/.config/NzbDrone /home/"${user}"/.config/sonarr
        fi

        systemctl stop sonarr@"${SONARR_OLD_OWNER}"

        # We don't have the debconf configuration yet so we can't migrate the data.
        # Instead we symlink so postinst knows where it's at.
        if [ -f "/usr/lib/sonarr/nzbdrone-appdata" ]; then
            rm "/usr/lib/sonarr/nzbdrone-appdata"
        else
            mkdir -p "/usr/lib/sonarr"
        fi

        echo_progress_start "Removing Sonarr v2"
        # shellcheck source=scripts/remove/sonarrold.sh
        bash /etc/swizzin/scripts/remove/sonarrold.sh
        echo_progress_done
    fi
}

_add_sonarr_repos() {
    echo_progress_start "Adding apt sources for Sonarr v3"
    codename=$(lsb_release -cs)
    distribution=$(lsb_release -is)

    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8 >> "$log" 2>&1
    echo "deb https://apt.sonarr.tv/${distribution,,} ${codename,,} main" | tee /etc/apt/sources.list.d/sonarr.list >> "$log" 2>&1

    #shellcheck source=sources/functions/mono
    . /etc/swizzin/sources/functions/mono
    mono_repo_setup
    echo_progress_done "Sources added"

    if ! apt-cache policy sonarr | grep -q apt.sonarr.tv; then
        echo_error "Sonarr was not found from apt.sonarr.tv repository. Please inspect the logs and try again later."
        exit 1
    fi
}

_install_sonarr() {
    mkdir -p "$sonarrv3confdir"
    chown "$user":"$user" /home/"$user"/.config
    chown "$user":"$user" -R "$sonarrv3confdir"

    # settings relevant from https://github.com/Sonarr/Sonarr/blob/phantom-develop/distribution/debian/config
    echo "sonarr sonarr/owning_user string ${user}" | debconf-set-selections
    echo "sonarr sonarr/owning_group string ${user}" | debconf-set-selections
    echo "sonarr sonarr/config_directory string ${sonarrv3confdir}" | debconf-set-selections
    apt_install sonarr sqlite3
    touch /install/.sonarr.lock
    sleep 1

    if [[ ! -d /usr/lib/sonarr ]]; then
        echo_error "The Sonarr v3 pacakge did not install correctly. Please try again. (Is sonarr repo reachable?)"
        exit 1
    fi

    echo_progress_start "Sonarr is installing an internal upgrade..."
    if ! timeout 30 bash -c -- "while ! curl -sIL http://127.0.0.1:8989 >> \"$log\" 2>&1; do sleep 2; done"; then
        echo_error "The Sonarr web server has taken longer than 30 seconds to start."
        exit 1
    fi
    echo_progress_done "Internal upgrade finished"
}

_nginx_sonarr() {
    if [[ -f /install/.nginx.lock ]]; then
        #TODO what is this sleep here for? See if this can be fixed by doing a check for whatever it needs to
        echo_progress_start "Installing nginx configuration"
        sleep 10
        bash /usr/local/bin/swizzin/nginx/sonarr.sh
        systemctl reload nginx >> "$log" 2>&1
        echo_progress_done
    else
        echo_info "Sonarr will run on port 8989"
    fi
}

_sonarrold_flow
_add_sonarr_repos
_install_sonarr
_nginx_sonarr

touch /install/.sonarr.lock

if [[ -f /install/.ombi.lock ]]; then
    echo_info "Please adjust your Ombi setup accordingly"
fi

if [[ -f /install/.tautulli.lock ]]; then
    echo_info "Please adjust your Tautulli setup accordingly"
fi

if [[ -f /install/.bazarr.lock ]]; then
    echo_info "Please adjust your Bazarr setup accordingly"
fi

echo_success "Sonarr v3 installed"
