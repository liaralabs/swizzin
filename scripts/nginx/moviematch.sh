#!/bin/bash

cat > /etc/nginx/apps/moviematch.conf << NGINX
    location ^~ /moviematch/ {
        proxy_pass http://127.0.0.1:8420/;
        proxy_set_header Upgrade \$http_upgrade;
    }
NGINX

echo "host: 0.0.0.0
basePath: /moviematch" >> /opt/moviematch/config.yaml
systemctl daemon-reload
systemctl try-restart moviematch -q
