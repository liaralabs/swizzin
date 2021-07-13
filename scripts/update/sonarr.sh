#!/bin/bash

if dpkg -l | grep nzbdrone > /dev/null 2>&1; then
    v2present=true
    echo_warn "Sonarr v2 is obsolete and end-of-life. Please upgrade your Sonarr to v3 using \`box upgrade sonarr\`."
fi

if [[ -f /install/.sonarr.lock ]] && [[ $v2present == "true" ]]; then
    echo_info "box package sonarr is being renamed to sonarrold"
    #update lock file
    rm /install/.sonarr.lock
    if [[ -f /install/.nginx.lock ]]; then
        mv /etc/nginx/apps/sonarr.conf /etc/nginx/apps/sonarrold.conf
        systemctl reload nginx
    fi
    touch /install/.sonarrold.lock
fi

if [[ -f /install/.sonarrv3.lock ]]; then
    echo_info "box package sonarrv3 is being renamed to sonarr as it has been released as stable"
    #upgrade sonarr v3 lock
    if [[ -f /install/.nginx.lock ]]; then
        mv /etc/nginx/apps/sonarrv3.conf /etc/nginx/apps/sonarr.conf
        systemctl reload nginx
    fi
    rm /install/.sonarrv3.lock
    touch /install/.sonarr.lock
fi

# If we know we're running v3 Sonarr...
if [[ -f /install/.sonarr.lock ]] && [[ $v2present != "true" ]]; then
    # Ensure the sonarr owner is recorded
    if [ -z "$SONARR_OWNER" ]; then
        if ! SONARR_OWNER="$(swizdb get sonarr/owner)"; then
            master=$(_get_master_username)
            if [ ! -d /home/"$master"/.config/sonarr ]; then
                echo_error "Could not find Sonarr config in master's home folder. Please export the variable \"SONARR_OWNER\" and run \`box update\` again."
                # Stop the box updater because who knows what could rely on this in the future
                exit 1
            fi
            SONARR_OWNER="$master"
            echo_info "Setting sonarr owner = $SONARR_OWNER"
            swizdb set "sonarr/owner" "$SONARR_OWNER"
        fi
    else
        echo_info "Setting sonarr owner = $SONARR_OWNER"
        swizdb set "sonarr/owner" "$SONARR_OWNER"
    fi
fi
