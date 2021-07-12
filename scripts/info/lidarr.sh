#!/usr/bin/env bash

paths+=(/home/"$master"/.config/Lidarr/logs/Lidarr.txt)
paths+=(/home/"$master"/.config/Lidarr/logs/Lidarr.{0..2}.txt)
paths+=(/home/"$master"/.config/Lidarr/logs/Lidarr.debug.txt)
paths+=(/home/"$master"/.config/Lidarr/logs/Lidarr.trace.txt)
commands+=(journalctl -u lidarr)

apikey=$(awk -F '[<>]' '/ApiKey/{print $3}' /home/"${master}"/.config/Lidarr/config.xml)
app_sensitive+=("$apikey" "###-Lidarr-api-key-###")
