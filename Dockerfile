FROM mariadb:10.7-focal
ENV DEBIAN_FRONTEND noninteractive

ENV PILER_USER piler
ENV PILER_DEB "https://bitbucket.org/jsuto/piler/downloads/piler_1.3.11-focal-5c2ceb1_amd64.deb"
ENV SPHINX_VERSION "3.4.1"
ENV SPHINX_DOWNLOAD_URL "http://sphinxsearch.com/files/sphinx-3.4.1-efbcc65-linux-amd64.tar.gz"


RUN \
# Update and get dependencies
    apt-get update && \
    apt-get -y --no-install-recommends install \
    apt-utils nano wget rsyslog openssl sysstat php7.4-cli php7.4-cgi php7.4-mysql php7.4-fpm php7.4-zip php7.4-ldap \
    php7.4-gd php7.4-curl php7.4-xml php7.4-memcached catdoc unrtf poppler-utils nginx tnef sudo libzip5 \
    libtre5 cron python3 python3-mysqldb ca-certificates curl supervisor default-libmysqlclient-dev  mariadb-client && \
    # Cleanup
    apt-get -y autoremove && \
    apt-get -y clean 
    
# Install Sphinxsearch
 RUN wget -O sphinx-${SPHINX_VERSION}-bin.tar.gz ${SPHINX_DOWNLOAD_URL} && \
    tar zxvf sphinx-${SPHINX_VERSION}-bin.tar.gz && \
    rm -f sphinx-${SPHINX_VERSION}-bin.tar.gz && \
    mv sphinx-${SPHINX_VERSION}/bin/* /usr/bin/ && \
    rm -rf sphinx-${SPHINX_VERSION}/

RUN \
    echo "Adding piler user" && \
    addgroup "$PILER_USER" && \
    useradd -ms /bin/bash -g "$PILER_USER" "$PILER_USER"

RUN curl -J -L -o /tmp/piler.deb "$PILER_DEB" && \
    dpkg -i /tmp/piler.deb && \
    echo "Adding cron job" && \
    crontab -u $PILER_USER /usr/share/piler/piler.cron && \
    rm -f /tmp/piler.deb


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