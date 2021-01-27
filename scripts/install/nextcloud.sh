#!/bin/bash
#
# [Install nextcloud package]
#
# Author:   liara for QuickBox.io
# Ported to swizzin by liara
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

if [[ ! -f /install/.nginx.lock ]]; then
    echo_error "Nginx not detected. Please install nginx and restart panel install."
    exit 1
fi

function _db_setup() {
    #Check for existing mysql and install if not found
    if ! which mysql >> /dev/null; then
        apt_install mariadb-server
        systemctl enable --now mysql -q
    fi

    if [[ -z $nextcldMySqlPW ]]; then
        nextcldMySqlPW=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)
        echo_log_only "Nextcloud DB password = $nextcldMySqlPW"
    fi

    # BIG TODO HERE https://docs.nextcloud.com/server/18/admin_manual/configuration_database/mysql_4byte_support.html
    echo_progress_start "Setting up DB for Nextcloud"
    mysql --execute="CREATE DATABASE nextcloud character set UTF8mb4 COLLATE utf8mb4_general_ci;" || exit 1
    mysql --execute="CREATE USER nextcloud@localhost IDENTIFIED BY '$nextcldMySqlPW';" || exit 1
    mysql --execute="GRANT ALL PRIVILEGES ON nextcloud.* TO nextcloud@localhost;" || exit 1
    # mysql --execute="SET GLOBAL innodb_file_format=Barracuda;"
    mysql --execute="FLUSH PRIVILEGES;"

    if ! grep -Fxq innodb_file_per_table=1 /etc/mysql/my.cnf; then
        echo_log_only "Fixing innodb file per table"
        if ! grep -Fxq '[mysqld]' /etc/mysql/my.cnf; then
            cat >> /etc/mysql/my.cnf << EOF
[mysqld]
innodb_file_per_table=1
EOF
        else
            sed '/^[mysqld]/a innodb_file_per_table=1' /etc/mysql/my.cnf
        fi
    fi
    echo_progress_done "DB Set up"
    systemctl restart mysqld
}

function _install() {
    #Depends
    apt_install unzip php-mysql libxml2-dev php-common php-gd php-json php-curl php-zip php-xml php-mbstring php-intl php-bcmath php-gmp php-imagick # php-apcu

    echo_progress_start "Downloading and extracting Nextcloud"
    codename=$(lsb_release -cs)
    if [[ $codename =~ ("stretch"|"xenial") ]]; then # TODO switch to PHP check instead
        echo_info "Switching to Nextcloud 15 due to an outdated version of PHP set by the OS"
        version="nextcloud-$(curl -s https://nextcloud.com/changelog/ | grep -A5 '"latest15"' | grep 'id=' | cut -d'"' -f2 | sed 's/-/./g')"
    else
        version=latest
    fi
    # TODO switch to tar.bz2 and curl?
    wget -q https://download.nextcloud.com/server/releases/${version}.zip -nc -O /tmp/nextcloud.zip >> "$log" 2>&1
    echo_progress_done "Downloaded"

    echo_progress_start "Extracting nextcloud"
    unzip -q /tmp/nextcloud.zip -d /srv >> "$log" 2>&1
    echo_progress_done "Extracted"

    #Set permissions as per nextcloud
    echo_progress_start "Configuring permissions"
    ocpath='/srv/nextcloud'
    htuser='www-data'
    htgroup='www-data'

    mkdir -p $ocpath/{data,assets,updater}
    find ${ocpath}/ -type f -print0 | xargs -0 chmod 0640
    find ${ocpath}/ -type d -print0 | xargs -0 chmod 0750
    chown -R root:${htgroup} ${ocpath}/
    chown -R ${htuser}:${htgroup} ${ocpath}/{apps,assets,config,data,themes,updater}
    chmod +x ${ocpath}/occ
    if [ -f ${ocpath}/.htaccess ]; then
        chmod 0644 ${ocpath}/.htaccess
        chown root:${htgroup} ${ocpath}/.htaccess
    fi
    if [ -f ${ocpath}/data/.htaccess ]; then
        chmod 0644 ${ocpath}/data/.htaccess
        chown root:${htgroup} ${ocpath}/data/.htaccess
    fi
    echo_progress_done "Permissions set"

    # echo "Installing cron jobs"
    crontab -l -u $htuser > /tmp/newcron.txt
    echo "*/5  *  *  *  * php -f /var/www/nextcloud/" >> /tmp/newcron.txt
    crontab -u $htuser /tmp/newcron.txt
    rm /tmp/newcron.txt

    touch /install/.nextcloud.lock

}

function _nginx() {
    echo_progress_start "Configuting nginx and PHP"
    bash /etc/swizzin/scripts/nginx/nextcloud.sh
    systemctl reload nginx
    echo_progress_done "nginx and PHP setup"
}

function _bootstrap() {
    echo_progress_start "Configuring Nextcloud settings"

    _occ "maintenance:install -n --database 'mysql' --database-name 'nextcloud'  --database-user 'nextcloud' --database-pass '$nextcldMySqlPW' --admin-user '$masteruser' --admin-pass '$masterpass' " -q
    _occ "maintenance:mode --on -n" -q
    _occ "db:add-missing-indices-n " -q
    _occ "db:convert-filecache-bigint --no-interaction -n" -q
    # _occ "config:system:set memcache.local --value='\OC\Memcache\APCu" -q # TODO follow https://github.com/nextcloud/server/issues/24567

    _occ_add_trusted_domain "localhost" >> $log
    _occ_add_trusted_domain "$(hostname)" >> $log
    _occ_add_trusted_domain "$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')" >> $log
    for value in $(grep server_name /etc/nginx/sites-enabled/default | cut -d' ' -f 4 | cut -d\; -f 1); do
        if [[ $value != "_" ]]; then
            _occ_add_trusted_domain "$(value)" >> $log
        fi
    done
    #All users but the master user

    _occ "maintenance:mode --off" -q
    restart_php_fpm
    systemctl restart nginx
    echo_progress_done "Nextcloud configured"
}

function _users() {
    for u in "${users[@]}"; do
        echo_progress_start "Adding $u to Nextcloud"
        OC_PASS=$(_get_user_password "$u")
        export OC_PASS
        #TODO decide what happens wih the stdout from this
        if ! _occ "user:add --password-from-env --display-name=${u} --group='users' ${u}" -q; then
            echo_error "Error adding user"
            exit 1
        fi
        unset OC_PASS
        echo_progress_done "$u added to nextcloud"
    done
}

# shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
# shellcheck source=sources/functions/nextcloud
. /etc/swizzin/sources/functions/nextcloud
# shellcheck source=sources/functions/php
. /etc/swizzin/sources/functions/php

masteruser=$(_get_master_username)
masterpass=$(_get_user_password "$masteruser")

if [[ -n $1 ]]; then
    users=("$1")
    _users
    exit 0
fi

_install
_db_setup
_nginx
_bootstrap
readarray -t users < <(_get_user_list | sed "/^$masteruser\b/Id")
_users

echo_success "Nextcloud installed"
echo_info "Please log in using your master credentials."
