#!/usr/bin/env bash

cat > /etc/nginx/apps/trackarr.conf << EOF
location /trackarr/ {
  proxy_pass http://127.0.0.1:7337/;
}
EOF

. /etc/swizzin/sources/functions/utils
master=$(_get_master_username)
pass=$(_get_user_password "$master")
sed -i "s|^baseurl: /$|baseurl: /trackarr |" /opt/trackarr/config.yaml
if ! grep -q user:; then
    sed -i "/^server:*/a \ \ user: $master" /opt/trackarr/config.yaml
    sed -i "/^server:*/a \ \ pass: $pass" /opt/trackarr/config.yaml
fi
