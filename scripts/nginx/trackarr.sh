#!/usr/bin/env bash

. /etc/swizzin/sources/functions/utils
user=$(_get_master_username)
cat > /etc/nginx/apps/trackarr.conf << EOF
location /trackarr/ {
    proxy_pass              http://127.0.0.1:7337/trackarr;
    proxy_set_header        X-Forwarded-Host        \$http_host;
}
EOF

sed -i "s|baseurl: /$|baseurl: /trackarr|" /opt/trackarr/config.yaml
sed -i "s|host: 0.0.0.0|host: 127.0.0.1|" /opt/trackarr/config.yaml
sed -i "s|publicurl: http://trackarr.domain.com|publicurl: http://127.0.0.1/trackarr|" /opt/trackarr/config.yaml

systemctl try-restart trackarr
