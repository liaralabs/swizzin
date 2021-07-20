#!/usr/bin/env bash

. /etc/swizzin/sources/functions/utils
user=$(_get_master_username)
cat > /etc/nginx/apps/trackarr.conf << EOF
location /trackarr/ {
    proxy_pass              http://127.0.0.1:7337/trackarr/;
    proxy_set_header        Host                    \$proxy_host;
    proxy_set_header        X-Forwarded-Host        \$http_host;

    proxy_set_header        Upgrade                 \$http_upgrade;
    proxy_set_header        Connection              "Upgrade";
    
    auth_basic              "What's the password?";
    auth_basic_user_file    /etc/htpasswd.d/htpasswd.${user};
}
EOF

# Prevent double-basic-auth req if nginx was installed after trackarr
# sed -i '/user:/d' /opt/trackarr/config.yaml
# sed -i '/pass:/d' /opt/trackarr/config.yaml

sed -i "s|baseurl: /$|baseurl: /trackarr|" /opt/trackarr/config.yaml
sed -i "s|host: 0.0.0.0|host: 127.0.0.1|" /opt/trackarr/config.yaml
sed -i "s|publicurl: http://trackarr.domain.com|publicurl: http://127.0.0.1/trackarr|" /opt/trackarr/config.yaml

systemctl try-restart trackarr
