#!/usr/bin/env bash

if [ ! -e "/install/.overseerr.lock" ]; then
    echo_error "Not installed to begin with"
    exit 1
fi

# TODO check if current and latest released version can be compared

if [[ $(systemctl is-active overseerr) == "active" ]]; then
    wasActive="true"
    echo_progress_start "Shutting down overseerr"
    systemctl stop overseerr
    echo_progress_done
fi

#shellcheck source=sources/functions/overseerr
. /etc/swizzin/sources/functions/overseerr
overseerr_install

if [[ $wasActive = "true" ]]; then
    echo_progress_start "Restarting overseerr"
    systemctl start overseerr
    echo_progress_done
fi
