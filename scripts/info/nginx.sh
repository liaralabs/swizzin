#!/usr/bin/env bash
commands+=("jounralctl -u nginx")
commands+=('nginx -T')
commands+=('nginx -V')
paths+=(/var/log/nginx/error.log)
#shellcheck source=sources/functions/php
. /etc/swizzin/sources/functions/php
paths+=("/var/log/php$(php_service_version)-fpm.log")
# TODO add IPV6 addresses?
app_sensitive+=("client: [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" "client: ###-CLIENTIP-###")
version="$(dpkg -s nginx-core | grep ^Version | cut -f2 -d' ')"
