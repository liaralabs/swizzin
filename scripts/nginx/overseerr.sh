#!/usr/bin/env bash

cat > /etc/nginx/apps/overseerr.conf << EOF
location /overseerr/ {
  proxy_pass http://localhost:5055/;
}
EOF

cat > /opt/overseerr/env.conf << EOF

# specify on which interface to listen, by default overseerr listens on all interfaces
HOST=127.0.0.1
EOF

systemctl try-restart overseerr
