#!/usr/bin/env bash

paths+=("/var/log/php$(php_service_version)-fpm.log")
commands+=("git -C /srv/rutorrent log -1 --pretty=format:(%h) \`%s\` %d %an")
