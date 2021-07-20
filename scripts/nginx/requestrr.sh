#!/bin/bash
# Nginx Configuration for requestrr
master=$(_get_master_username)

cat > /etc/nginx/apps/requestrr.conf << SRC
location ^~ /requestrr {
  proxy_pass        http://127.0.0.1:4545/requestrr;
  proxy_set_header Host \$proxy_host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_redirect off;
  # Basic Auth if Wanted
  ### This shouldn't be needed
  ### auth_basic "What's the password?";
  ### auth_basic_user_file /etc/htpasswd.d/htpasswd;
}
SRC
cat > /opt/requestrr/appsettings.json << SET
{
  "Logging": {
    "LogLevel": {
      "Default": "None"
    }
  },
  "AllowedHosts": "127.0.0.1"
}
SET
