#!/bin/bash
# Scrutiny nginx configuration by flying_sausages for Swizzin 2020
# GPLv3 applies

scrutinydir="/opt/scrutiny"
webport=8086
user=$(cut -d: -f1 < /root/.master.info)

cat > /etc/nginx/apps/scrutiny.conf <<EOF
location /scrutiny/ {
  proxy_pass http://localhost:$webport/;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
EOF
sed -i 's/"# backend"/"backend"/' "${scrutinydir}"/config/scrutiny.yaml
sed -i 's/"# basepath"/"baseurl"/' "${scrutinydir}"/config/scrutiny.yaml
systemctl restart scrutiny-web.service
