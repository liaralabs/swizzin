#!/usr/bin/env bash

paths+=(/home/"$master"/.config/sonarr/logs/sonarr.txt)
paths+=(/home/"$master"/.config/sonarr/logs/sonarr.{0..2}.txt)
paths+=(/home/"$master"/.config/sonarr/logs/sonarr.debug.txt)
paths+=(/home/"$master"/.config/sonarr/logs/sonarr.trace.txt)
commands+=(journalctl -u sonarr)

apikey=$(awk -F '[<>]' '/ApiKey/{print $3}' /home/"${master}"/.config/sonarr/config.xml)
app_sensitive+=("$apikey" "###-Sonarr-api-key-###")
