FROM ubuntu:20.04
ENV DEBIAN_FRONTEND noninteractive
ENV PILER_USER piler
ENV SPHINX_BIN_TARGZ sphinx-3.3.1-bin.tar.gz
ENV PILER_HOSTNAME localhost
ENV PILER_DEB https://bitbucket.org/jsuto/piler/downloads/piler_1.3.11-focal-5c2ceb1_amd64.deb
ENV SPHINX_DOWNLOAD_URL https://sphinxsearch.com/files/sphinx-3.3.1-b72d67b-linux-amd64.tar.gz

RUN \
# Update and get dependencies
    apt-get update && \
    apt-get -y --no-install-recommends install \
    apt-utils wget rsyslog openssl sysstat php7.4-cli php7.4-cgi php7.4-mysql php7.4-fpm php7.4-zip php7.4-ldap \
    php7.4-gd php7.4-curl php7.4-xml php7.4-memcached catdoc unrtf poppler-utils nginx tnef sudo libzip5 \
    libtre5 cron libmariadb-dev mariadb-client-core-10.3 python3 python3-mysqldb ca-certificates curl supervisor && \
# Cleanup
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

# Install Sphinxsearch
 RUN wget --no-check-certificate -q -O ${SPHINX_BIN_TARGZ} ${SPHINX_DOWNLOAD_URL} && \
    tar zxvf ${SPHINX_BIN_TARGZ} && \
    rm -f ${SPHINX_BIN_TARGZ} && \
    cp sphinx-3.3.1/bin/* /usr/bin/

COPY rootfs /
RUN \
# Make directory
    mkdir /usr/share/piler && \
# Move files
    mv /tmp/startup.sh /usr/share/piler/startup.sh && \
    mv /tmp/config-site.php /usr/share/piler/config-site.php && \
    mv /tmp/wait.sh /usr/share/piler/wait.sh && \
    mv /tmp/db-mysql.sql /usr/share/piler/db-mysql.sql && \
# Change permissions
    chmod +x /usr/share/piler/startup.sh &&\
    chmod +x /usr/share/piler/wait.sh 
EXPOSE 25/tcp
EXPOSE 80/tcp
EXPOSE 443/tcp

ENTRYPOINT ["/usr/share/piler/startup.sh"]
VOLUME /var/piler/store/00 /var/piler/sphinx /etc/piler
