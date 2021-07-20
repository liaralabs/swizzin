#!/usr/bin/env bash

cat > /etc/nginx/apps/calibrecs.conf << EOF
proxy_set_header X-Forwarded-For \$remote_addr;
location /calibrecs/ {
    proxy_buffering         off;
    proxy_pass              http://127.0.0.1:8089\$request_uri;
    auth_basic              "What's the password?";
    auth_basic_user_file    /etc/htpasswd;
}
location /calibrecs {
    # we need a trailing slash for the Application Cache to work
    rewrite                 /calibrecs /calibrecs/ permanent;
}
EOF

sed '/ExecStart=/ s/$/ --listen-on 127.0.0.1 --url-prefix \/calibrecs --enable-local-write/' -i /etc/systemd/system/calibrecs.service

systemctl daemon-reload
systemctl try-restart calibrecs
