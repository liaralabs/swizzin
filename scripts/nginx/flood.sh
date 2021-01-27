#!/bin/bash
# nginx configuration for flood
# Author: flying_sausages

cat > /etc/nginx/apps/flood.conf << EOF
location /flood/api {
  proxy_pass http://127.0.0.1:3006;
  proxy_buffering off;
  proxy_cache off;
}

location /flood {
    return 301 \$scheme://\$host/flood/;
}

location /flood/ {
  alias /usr/lib/node_modules/flood/dist/assets/;
  try_files \$uri /flood/index.html;
}
EOF

sed '/ExecStart=/ s/$/ --baseuri=\/flood/' -i /etc/systemd/system/flood.service
systemctl daemon-reload
systemctl try-restart flood
