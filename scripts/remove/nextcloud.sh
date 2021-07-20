#!/bin/bash
# nextcloud uninstaller
echo_query "Please enter mysql root password so that nextcloud database and user can be dropped." "hidden"
read -s 'password'
rm -rf /srv/nextcloud
rm /etc/nginx/apps/nextcloud.conf
systemctl reload nginx

if ask "Would you like to also remove the mysql/mariadb server?" N; then
    apt_remove mariadb-server --purge
else
    echo_progress_start "Dropping nextcloud tables and user"
    host=$(mysql -u root --password="$password" --execute="select host from mysql.user where user = 'nextcloud';" | grep -E "localhost|127.0.0.1")
    mysql --user="root" --password="$password" --execute="DROP DATABASE nextcloud;"
    mysql --user="root" --password="$password" --execute="DROP USER nextcloud@$host;"
    echo_progress_done "Nextcloud dropped from database"
fi

rm /install/.nextcloud.lock
