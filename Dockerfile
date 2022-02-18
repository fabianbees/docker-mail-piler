#FROM ubuntu:20.04
FROM mariadb:10.7-focal
ENV DEBIAN_FRONTEND noninteractive
ENV PILER_USER piler
ENV SPHINX_BIN_TARGZ sphinx-3.3.1-bin.tar.gz
ENV PILER_HOSTNAME localhost
ENV PILER_DEB https://bitbucket.org/jsuto/piler/downloads/piler_1.3.11-focal-5c2ceb1_amd64.deb
ENV SPHINX_DOWNLOAD_URL https://sphinxsearch.com/files/sphinx-3.3.1-b72d67b-linux-amd64.tar.gz

#http://sphinxsearch.com/files/sphinx-3.4.1-efbcc65-linux-amd64.tar.gz
#https://sphinxsearch.com/files/sphinx-3.3.1-b72d67b-linux-amd64.tar.gz

#ENV PILER_HOSTNAME: "localhost"
#ENV PILER_RETENTION: "3650"
#ENV MYSQL_HOSTNAME: "localhost"
#ENV MYSQL_DATABASE: "piler"
#ENV MYSQL_USERNAME: "piler"
#ENV MYSQL_PASSWORD: "piler123"
ENV PILER_HOSTNAME=localhost
ENV PILER_RETENTION=3650
ENV MYSQL_HOSTNAME=localhost
ENV MYSQL_DATABASE=piler
ENV MYSQL_USERNAME=root
ENV MYSQL_PASSWORD=piler123
ENV MARIADB_ROOT_PASSWORD=piler123

ENV DATAROOTDIR="/usr/share"
ENV SYSCONFDIR="/etc"
ENV SPHINXCFG="/etc/piler/sphinx.conf"
ENV PILER_RETENTION=${PILER_RETENTION:-2557}
ENV PILER_HOST=${PILER_HOST:-archive.yourdomain.com}
ENV PILER_CONF="/etc/piler/piler.conf"
ENV PILER_PEM="/etc/piler/piler.pem"
ENV CONFIG_SITE_PHP="/etc/piler/config-site.php"
ENV CONFIG_PHP="/var/piler/www/config.php"
ENV WAIT_FOR_IT="/usr/share/piler/wait.sh"
ENV PILER_MYSQL_CNF="/etc/piler/.my.cnf"
ENV SSL_CERT_DATA="/C=US/ST=Denial/L=Springfield/O=Dis/CN=${PILER_HOSTNAME}"

RUN \
# Update and get dependencies
    apt-get update && \
    apt-get -y --no-install-recommends install \
    apt-utils nano wget rsyslog openssl sysstat php7.4-cli php7.4-cgi php7.4-mysql php7.4-fpm php7.4-zip php7.4-ldap \
    php7.4-gd php7.4-curl php7.4-xml php7.4-memcached catdoc unrtf poppler-utils nginx tnef sudo libzip5 \
    libtre5 cron python3 python3-mysqldb ca-certificates curl supervisor default-libmysqlclient-dev  mariadb-client && \
    # libmariadb-dev mariadb-client-core-10.3 libmariadb-dev
# Cleanup
    apt-get -y autoremove && \
    apt-get -y clean 
    #&& \
    #rm -rf /var/lib/apt/lists/* && \
    #rm -rf /tmp/* && \
    #rm -rf /var/tmp/*

# Install Sphinxsearch
 RUN wget --no-check-certificate -q -O ${SPHINX_BIN_TARGZ} ${SPHINX_DOWNLOAD_URL} && \
    tar zxvf ${SPHINX_BIN_TARGZ} && \
    rm -f ${SPHINX_BIN_TARGZ} && \
    cp sphinx-3.3.1/bin/* /usr/bin/

#COPY rootfs /
RUN \
    echo "Adding piler user" && \
    addgroup "$PILER_USER" && \
    useradd -ms /bin/bash -g "$PILER_USER" "$PILER_USER"

RUN curl -J -L -o /tmp/piler.deb "$PILER_DEB" && \
    dpkg -i /tmp/piler.deb && \
    echo "Adding cron job" && \
    crontab -u $PILER_USER /usr/share/piler/piler.cron

# update config files
RUN printf "[mysql]\nhost = ${MYSQL_HOSTNAME}\nuser = ${MYSQL_USERNAME}\npassword = ${MYSQL_PASSWORD}\n\n[mysqldump]\nhost = ${MYSQL_HOSTNAME}\nuser = ${MYSQL_USERNAME}\npassword = ${MYSQL_PASSWORD}\n" > "$PILER_MYSQL_CNF" && \
    chown piler:piler "$PILER_MYSQL_CNF"  && \
    chmod 400 "$PILER_MYSQL_CNF"  && \

    echo "Updating sphinx configuration" && \
    sed -e "s%MYSQL_HOSTNAME%$MYSQL_HOSTNAME%" -e "s%MYSQL_DATABASE%$MYSQL_DATABASE%" -e "s%MYSQL_USERNAME%$MYSQL_USERNAME%" -e "s%MYSQL_PASSWORD%$MYSQL_PASSWORD%" $SYSCONFDIR/piler/sphinx.conf.dist > $SPHINXCFG && \

    echo "Updating piler.conf configuration" && \
    pilerconf | grep -v mysqlsocket | \
    sed -e "s/tls_enable=0/tls_enable=1/g" \
        -e "s/hostid=mailarchiver/hostid=${PILER_HOSTNAME}/g" \
        -e "s/mysqlport=0/mysqlport=3306/" \
        -e "s/default_retention_days=2557/default_retention_days=${PILER_RETENTION}/" \
        -e "s/mysqlpwd=/mysqlpwd=${MYSQL_PASSWORD}/" \
        -e "s/mysqlhost=/mysqlhost=${MYSQL_HOSTNAME}/" \
        -e "s/mysqluser=piler/mysqluser=${MYSQL_USERNAME}/" \
        -e "s/mysqldb=piler/mysqldb=${MYSQL_DATABASE}/" \
        -e "s/pemfile=/pemfile=\/etc\/piler\/piler.pem/" > "$PILER_CONF" && \
    chmod 600 "$PILER_CONF" && \
    chown $PILER_USER:$PILER_USER /etc/piler/piler.conf



COPY rootfs/tmp/startup.sh rootfs/tmp/config-site.php rootfs/tmp/wait.sh rootfs/tmp/db-mysql.sql /usr/share/piler/
COPY rootfs/etc/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY rootfs/etc/nginx/nginx.conf /rootfs/etc/nginx/piler.conf /etc/nginx/

# Change permissions
RUN chmod +x /usr/share/piler/startup.sh && \
    chmod +x /usr/share/piler/wait.sh




EXPOSE 25/tcp
EXPOSE 80/tcp
EXPOSE 443/tcp

ENTRYPOINT ["/usr/share/piler/startup.sh"]
VOLUME /var/piler/store/00 /var/piler/sphinx /etc/piler /var/lib/mysql

