#!/usr/bin/env bash

paths+=("/var/lib/emby/logs/*")
commands+=("journalctl -u emby")
