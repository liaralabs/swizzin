#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

if [[ -z $1 ]]; then
    echo_error "Need a parameter..."
    exit 1
fi

# run all functions, if one fails, mark as bad
check_service "$1" || bad="true"
check_port "$1" || bad="true"
check_port_curl "$1" || bad="true"
check_nginx "$1" || bad="true"

evaluate_bad
