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

RUN \
# Update and get dependencies
    apt-get update && \
    apt-get -y --no-install-recommends install \
    apt-utils wget rsyslog openssl sysstat php7.4-cli php7.4-cgi php7.4-mysql php7.4-fpm php7.4-zip php7.4-ldap \
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

COPY rootfs/tmp/startup.sh rootfs/tmp/config-site.php rootfs/tmp/wait.sh rootfs/tmp/db-mysql.sql /usr/share/piler/

# Change permissions
RUN chmod +x /usr/share/piler/startup.sh && \
    chmod +x /usr/share/piler/wait.sh




EXPOSE 25/tcp
EXPOSE 80/tcp
EXPOSE 443/tcp

ENTRYPOINT ["/usr/share/piler/startup.sh"]
VOLUME /var/piler/store/00 /var/piler/sphinx /etc/piler /var/lib/mysql

