#!/usr/bin/env bash

cat > /etc/nginx/apps/trackarr.conf << EOF
location /trackarr/ {
    proxy_pass              http://127.0.0.1:7337/trackarr;
    proxy_set_header        X-Forwarded-Host        \$http_host;
}
EOF

. /etc/swizzin/sources/functions/utils
master=$(_get_master_username)
pass=$(_get_user_password "$master")
sed -i "s|baseurl: /$|baseurl: /trackarr|" /opt/trackarr/config.yaml
sed -i "s|host: 0.0.0.0|host: 127.0.0.1|" /opt/trackarr/config.yaml

if ! grep -q "user:" /opt/trackarr/config.yaml; then
    sed -i "/^server:*/a \ \ user: $master" /opt/trackarr/config.yaml
    sed -i "/^server:*/a \ \ pass: $pass" /opt/trackarr/config.yaml
fi
