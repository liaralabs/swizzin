#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "readarr" || BAD=true
check_port_curl "8787" || BAD=true
check_nginx "readarr" || BAD=true

evaluate_bad
