#!/bin/bash
# Scrutiny nginx configuration by flying_sausages for Swizzin 2020
# GPLv3 applies

# TODO add baseurl to scrutiny config

# TODO install nginx config for scrutiny that works

echo "(not really m8)"

# scrutinydir="/opt/scrutiny"
# webport=8086
# user=$(cut -d: -f1 < /root/.master.info)

# cat > /etc/nginx/apps/scrutiny.conf <<EOF
# location /scrutiny/ {
#   proxy_pass http://localhost:$webport/;
#   auth_basic "What's the password?";
#   auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
# }
# EOF

# sed -i 's=baseurl: /=baseurl: /scrutiny=' "${scrutinydir}"/config/scrutiny.yaml
# systemctl restart scrutiny-web.service
