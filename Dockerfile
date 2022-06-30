FROM mariadb:10.8-jammy
ENV DEBIAN_FRONTEND noninteractive

ENV PILER_USER piler
ENV PILER_DEB "https://bitbucket.org/jsuto/piler/downloads/piler_1.3.12-focal-eb2b22b2_amd64.deb"
ENV SPHINX_VERSION "3.4.1"
ENV OPENSSL_VERSION "1.1.1p"
ENV SPHINX_DOWNLOAD_URL "http://sphinxsearch.com/files/sphinx-3.4.1-efbcc65-linux-amd64.tar.gz"


RUN \
# Update and get dependencies
    apt-get update && \
    apt-get -y --no-install-recommends install \
    apt-utils nano wget rsyslog openssl sysstat php8.1-cli php8.1-cgi php8.1-mysql php8.1-fpm php8.1-zip \
    php8.1-ldap php8.1-gd php8.1-curl php8.1-xml php8.1-memcached catdoc unrtf poppler-utils nginx tnef sudo \
    libtre5 cron python3 python3-mysqldb ca-certificates curl supervisor default-libmysqlclient-dev mariadb-client && \
    # Cleanup
    apt-get -y autoremove && \
    apt-get -y clean

# Install missing openssl dependency
RUN apt install -y make gcc && \
    wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    tar -xvf openssl-${OPENSSL_VERSION}.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    ./config && \
    make -j && \
    #make -j test && \
    make -j install && \
    cd / && rm -rf openssl-* && \
    # Cleanup
    apt remove -y make gcc && \
    apt-get -y autoremove && \
    apt-get -y clean

# Install missing libzip5 dependency
RUN wget http://de.archive.ubuntu.com/ubuntu/pool/universe/libz/libzip/libzip5_1.5.1-0ubuntu1_amd64.deb && \
    dpkg --force-all -i libzip5_1.5.1-0ubuntu1_amd64.deb && \
    rm libzip5_1.5.1-0ubuntu1_amd64.deb

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