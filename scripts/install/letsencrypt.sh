#!/bin/bash
# Let's Encrypt Installa
# nginx flavor by liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

if [[ ! -f /install/.nginx.lock ]]; then
    echo_error "This script is meant to be used in conjunction with nginx and it has not been installed. Please install nginx first and restart this installer."
    exit 1
fi

. /etc/swizzin/sources/functions/letsencrypt
ip=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')

if [[ -z $LE_HOSTNAME ]]; then
    echo_query "Enter domain name to secure with LE"
    read -e hostname
else
    hostname=$LE_HOSTNAME
fi

if [[ -z $LE_DEFAULTCONF ]]; then
    if ask "Do you want to apply this certificate to your swizzin default conf?"; then
        main=yes
    else
        main=no
    fi
else
    main=$LE_DEFAULTCONF
fi

if [[ $main == yes ]]; then
    sed -i "s/server_name .*;/server_name $hostname;/g" /etc/nginx/sites-enabled/default
fi

if [[ -n $LE_CF_API ]] || [[ -n $LE_CF_EMAIL ]] || [[ -n $LE_CF_ZONE ]]; then
    LE_BOOL_CF=yes
fi

if [[ -z $LE_BOOL_CF ]]; then
    if ask "Is your DNS managed by CloudFlare?"; then
        cf=yes
    else
        cf=no
    fi
else
    [[ $LE_BOOL_CF = "yes" ]] && cf=yes
    [[ $LE_BOOL_CF = "no" ]] && cf=no
fi

if [[ ${cf} == yes ]]; then

    if [[ $hostname =~ (\.cf$|\.ga$|\.gq$|\.ml$|\.tk$) ]]; then
        echo_error "Cloudflare does not support API calls for the following TLDs: cf, .ga, .gq, .ml, or .tk"
        exit 1
    fi

    if [[ -n $LE_CF_ZONE ]]; then
        LE_CF_ZONEEXISTS=no
    fi

    if [[ -z $LE_CF_ZONEEXISTS ]]; then
        if ask "Does the record for this subdomain already exist?"; then
            main=yes
        else
            main=no
        fi
    else
        [[ $LE_CF_ZONEEXISTS = "yes" ]] && zone=yes
        [[ $LE_CF_ZONEEXISTS = "no" ]] && zone=no
    fi

    if [[ -z $LE_CF_API ]]; then
        echo_query "Enter CF API key"
        read -e api
    else
        api=$LE_CF_API
    fi

    if [[ -z $LE_CF_EMAIL ]]; then
        echo_query "CF Email"
        read -e email
    else
        api=$LE_CF_EMAIL
    fi

    export CF_Key="${api}"
    export CF_Email="${email}"

    valid=$(curl -X GET "https://api.cloudflare.com/client/v4/user" -H "X-Auth-Email: $email" -H "X-Auth-Key: $api" -H "Content-Type: application/json")
    if [[ $valid == *"\"success\":false"* ]]; then
        message="API CALL FAILED. DUMPING RESULTS:\n$valid"
        echo_error "$message"
        exit 1
    fi

    if [[ ${record} == no ]]; then

        if [[ -z $LE_CF_ZONE ]]; then
            echo_query "Zone Name (example.com)"
            read -e zone
        else
            zone=$LE_CF_ZONE
        fi

        zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone" -H "X-Auth-Email: $email" -H "X-Auth-Key: $api" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
        addrecord=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records" -H "X-Auth-Email: $email" -H "X-Auth-Key: $api" -H "Content-Type: application/json" --data "{\"id\":\"$zoneid\",\"type\":\"A\",\"name\":\"$hostname\",\"content\":\"$ip\",\"proxied\":true}")
        if [[ $addrecord == *"\"success\":false"* ]]; then
            message="API UPDATE FAILED. DUMPING RESULTS:\n$addrecord"
            echo_error "$message"
            exit 1
        else
            message="DNS record added for $hostname at $ip"
            echo_info "$message"
        fi
    fi
fi

apt_install socat

if [[ ! -f /root/.acme.sh/acme.sh ]]; then
    echo_progress_start "Installing ACME script"
    curl https://get.acme.sh | sh >> $log 2>&1
    echo_progress_done
fi

mkdir -p /etc/nginx/ssl/${hostname}
chmod 700 /etc/nginx/ssl

/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt >> $log 2>&1 || {
    echo_warn "Could not set default certificate authority to Let's Encrypt. Upgrading acme.sh to retry."
    /root/.acme.sh/acme.sh --upgrade >> $log 2>&1 || {
        echo_error "Could not upgrade acme.sh."
        exit 1
    }
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt >> $log 2>&1 || {
        echo_error "Could not set default certificate authority to Let's Encrypt"
        exit 1
    }
    echo_info "acme.sh has been upgraded successfully."
}

echo_progress_start "Registering certificates"
if [[ ${cf} == yes ]]; then
    /root/.acme.sh/acme.sh --force --issue --dns dns_cf -d ${hostname} >> $log 2>&1 || {
        echo_error "Certificate could not be issued."
        exit 1
    }
else
    if [[ $main = yes ]]; then
        /root/.acme.sh/acme.sh --force --issue --nginx -d ${hostname} >> $log 2>&1 || {
            echo_error "Certificate could not be issued."
            exit 1
        }
    else
        systemctl stop nginx
        /root/.acme.sh/acme.sh --force --issue --standalone -d ${hostname} --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx" >> $log 2>&1 || {
            echo_error "Certificate could not be issued. Please check your info and try again"
            exit 1
        }
        sleep 1
        systemctl start nginx
    fi
fi
echo_progress_done "Certificate acquired"

echo_progress_start "Installing certificate"
/root/.acme.sh/acme.sh --force --install-cert -d ${hostname} --key-file /etc/nginx/ssl/${hostname}/key.pem --fullchain-file /etc/nginx/ssl/${hostname}/fullchain.pem --ca-file /etc/nginx/ssl/${hostname}/chain.pem --reloadcmd "systemctl reload nginx"
if [[ $main == yes ]]; then
    sed -i "s/ssl_certificate .*/ssl_certificate \/etc\/nginx\/ssl\/${hostname}\/fullchain.pem;/g" /etc/nginx/sites-enabled/default
    sed -i "s/ssl_certificate_key .*/ssl_certificate_key \/etc\/nginx\/ssl\/${hostname}\/key.pem;/g" /etc/nginx/sites-enabled/default
fi
echo_progress_done "Certificate installed"

# Add LE certs to ZNC, if installed.
if [[ -f /install/.znc.lock ]]; then
    le_znc_hook
fi

# Add LE certs to VSFTPD, if installed.
if [[ -f /install/.vsftpd.lock ]]; then
    le_vsftpd_hook
    systemctl restart vsftpd
fi

systemctl reload nginx

echo_success "Letsencrypt installed"
