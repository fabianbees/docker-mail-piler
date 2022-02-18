#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

script_path=$(readlink -f "$0")
basedir=${script_path%/*}
script_name=${script_path##*/}


MYSQL_HOSTNAME=localhost
PILER_HOSTNAME=localhost

DATAROOTDIR="/usr/share"
SPHINXCFG="/etc/piler/sphinx.conf"
PILER_RETENTION=${PILER_RETENTION:-2557}
PILER_HOST=${PILER_HOST:-archive.yourdomain.com}
PILER_CONF="/etc/piler/piler.conf"
PILER_PEM="/etc/piler/piler.pem"
CONFIG_SITE_PHP="/etc/piler/config-site.php"
CONFIG_PHP="/var/piler/www/config.php"
WAIT_FOR_IT="/usr/share/piler/wait.sh"
PILER_MYSQL_CNF="/etc/piler/.my.cnf"
SSL_CERT_DATA="/C=US/ST=Denial/L=Springfield/O=Dis/CN=${PILER_HOSTNAME}"


wait_for_sql() {
   /usr/local/bin/docker-entrypoint.sh mariadbd &
   echo "Waiting for the SQL database to come online"
   "$WAIT_FOR_IT" "${MYSQL_HOSTNAME}:3306 -s -t 0"
}

update_config_files() {
   if [[ ! -f "$PILER_MYSQL_CNF" ]]; then
      printf "[mysql]\nhost = ${MYSQL_HOSTNAME}\nuser = ${MYSQL_USER}\npassword = ${MYSQL_PASSWORD}\n\n[mysqldump]\nhost = ${MYSQL_HOSTNAME}\nuser = ${MYSQL_USER}\npassword = ${MYSQL_PASSWORD}\n" > "$PILER_MYSQL_CNF"
      chown piler:piler "$PILER_MYSQL_CNF"
      chmod 400 "$PILER_MYSQL_CNF"
   fi

   sed -e "s%MYSQL_HOSTNAME%$MYSQL_HOSTNAME%" -e "s%MYSQL_DATABASE%$MYSQL_DATABASE%" -e "s%MYSQL_USERNAME%$MYSQL_USER%" -e "s%MYSQL_PASSWORD%$MYSQL_PASSWORD%" /etc/piler/sphinx.conf.dist > $SPHINXCFG

   if [[ ! -f "$PILER_CONF" ]]; then
      echo "Updating piler.conf configuration"
      pilerconf | grep -v mysqlsocket | \
      sed -e "s/tls_enable=0/tls_enable=1/g" \
          -e "s/hostid=mailarchiver/hostid=${PILER_HOSTNAME}/g" \
          -e "s/mysqlport=0/mysqlport=3306/" \
          -e "s/default_retention_days=2557/default_retention_days=${PILER_RETENTION}/" \
          -e "s/mysqlpwd=/mysqlpwd=${MYSQL_PASSWORD}/" \
          -e "s/mysqlhost=/mysqlhost=${MYSQL_HOSTNAME}/" \
          -e "s/mysqluser=piler/mysqluser=${MYSQL_USER}/" \
          -e "s/mysqldb=piler/mysqldb=${MYSQL_DATABASE}/" \
          -e "s/pemfile=/pemfile=\/etc\/piler\/piler.pem/" > "$PILER_CONF"

      chmod 600 "$PILER_CONF"
      chown $PILER_USER:$PILER_USER /etc/piler/piler.conf
   fi

   echo "Updating piler PHP configuration"
   cp /usr/share/piler/config-site.php "$CONFIG_SITE_PHP"
   sed -i -e '/\$config\['\''SITE_NAME'\''\]/ s/= '\''HOSTNAME'\'';/= '\'''${PILER_HOSTNAME}''\'';/' "$CONFIG_SITE_PHP"
   sed -i -e '/\$config\['\''DB_DATABASE'\''\]/ s/= .*/= '\'''${MYSQL_DATABASE}''\'';/' "$CONFIG_SITE_PHP"
   sed -i -e '/\$config\['\''DB_PASSWORD'\''\]/ s/= .*/= '\'''${MYSQL_PASSWORD}''\'';/' "$CONFIG_SITE_PHP"
   sed -i -e '/\$config\['\''DB_HOSTNAME'\''\]/ s/= .*/= '\'''${MYSQL_HOSTNAME}''\'';/' "$CONFIG_SITE_PHP"
   sed -i -e '/\$config\['\''DB_USERNAME'\''\]/ s/= .*/= '\'''${MYSQL_USER}''\'';/' "$CONFIG_SITE_PHP"
   sed -i "s%^\$config\['DECRYPT_BINARY'\].*%\$config\['DECRYPT_BINARY'\] = '/usr/bin/pilerget';%" "$CONFIG_PHP"
   sed -i "s%^\$config\['DECRYPT_ATTACHMENT_BINARY'\].*%\$config\['DECRYPT_ATTACHMENT_BINARY'\] = '/usr/bin/pileraget';%" "$CONFIG_PHP"
   sed -i "s%^\$config\['PILER_BINARY'\].*%\$config\['PILER_BINARY'\] = '/usr/sbin/piler';%" "$CONFIG_PHP"

}


make_certificate() {
   if [[ ! -f "$PILER_PEM" ]]; then
      echo -n "Making an ssl certificate ... "
      openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "$SSL_CERT_DATA" -keyout "$PILER_PEM" -out 1.cert -sha1
      cat 1.cert >> "$PILER_PEM"
      chmod 640 "$PILER_PEM"
      chgrp "$PILER_USER" "$PILER_PEM"
      rm 1.cert
   fi
}


initialize_piler_data() {
   echo "Initilizing piler data"

   if [[ "$(echo "show tables" | mysql --defaults-file="$PILER_MYSQL_CNF" "$MYSQL_DATABASE")" == "" ]]; then
      echo "create database if not exists piler character set utf8mb4" | mysql --defaults-file="$PILER_MYSQL_CNF"
      mysql --defaults-file="$PILER_MYSQL_CNF" "$MYSQL_DATABASE" < /usr/share/piler/db-mysql.sql
   fi

   [[ -f /var/piler/sphinx/main1.spp ]] || su $PILER_USER -c "indexer --all --config ${SPHINXCFG}"
}

start_supervisored() {
   echo "Starting Supervisored"
   /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
}








wait_for_sql

update_config_files
make_certificate
initialize_piler_data

start_supervisored

