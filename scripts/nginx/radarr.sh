#!/bin/bash
# Nginx conf for Radarr v3
# Flying sausages 2020
master=$(cut -d: -f1 < /root/.master.info)

cat > /etc/nginx/apps/radarr.conf << RADARR
location /radarr {
  proxy_pass        http://127.0.0.1:7878/radarr;
  proxy_set_header Host \$proxy_host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_redirect off;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${master};

  proxy_http_version 1.1;
  proxy_set_header Upgrade \$http_upgrade;
  proxy_set_header Connection \$http_connection;
}
RADARR

isactive=$(systemctl is-active radarr)

if [[ $isactive == "active" ]]; then
    echo_log_only "Stopping radarr"
    systemctl stop radarr
fi
user=$(grep User /etc/systemd/system/radarr.service | cut -d= -f2)
echo_log_only "Radarr user detected as $user"
apikey=$(grep -oPm1 "(?<=<ApiKey>)[^<]+" /home/"$user"/.config/Radarr/config.xml)
# echo_log_only "Apikey = $apikey" >> "$log" # TODO sanitise this from the log
#TODO cahnge Branch whenever that becomes relevant

cat > /home/"$user"/.config/Radarr/config.xml << RADARR
<Config>
  <LogLevel>info</LogLevel>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <BindAddress>127.0.0.1</BindAddress>
  <Port>7878</Port>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <ApiKey>${apikey}</ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <UrlBase>radarr</UrlBase>
</Config>
RADARR

chown -R "$user":"$user" /home/"$user"/.config/Radarr

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
systemctl start radarr -q # Switch radarr on regardless whether it was off before or not as we need to have it online to trigger this cahnge
if ! timeout 15 bash -c -- "while ! curl -fL \"http://127.0.0.1:7878/api/v3/system/status?apiKey=${apikey}\" >> \"$log\" 2>&1; do sleep 5; done"; then
    echo_error "Radarr API did not respond as expected. Please make sure Radarr is on v3 and running."
    exit 1
else
    urlbase="$(curl -sL "http://127.0.0.1:7878/api/v3/config/host?apikey=${apikey}" | jq '.urlBase' | cut -d '"' -f 2)"
    echo_log_only "Radarr API tested and reachable"
fi

payload=$(curl -sL "http://127.0.0.1:7878/api/v3/config/host?apikey=${apikey}" | jq ".certificateValidation = \"disabledForLocalAddresses\"")
# echo_log_only "Payload = \n${payload}" # TODO sanitise API key out of the logs
echo_log_only "Return from radarr after PUT ="
curl -s "http://127.0.0.1:7878${urlbase}/api/v3/config/host?apikey=${apikey}" -X PUT -H 'Accept: application/json, text/javascript, */*; q=0.01' --compressed -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data-raw "${payload}"

# Switch radarr back off if it was dead before
if [[ $isactive != "active" ]]; then
    systemctl stop radarr
fi
