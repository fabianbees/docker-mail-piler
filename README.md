# Mail Piler Docker Container

## Description

This Docker deployment runs mariadb and Mail Piler with all its dependencies in a single container. 


Delault login credentials are as follows
```
admin@local
pilerrocks
```

Web-UI is accesible under port 80. (mostly `http://localhost`)


## Usage via plain docker cli

run the following command but edit your environment variables first:

```bash
docker run -d \
  --name=mail-piler \
  -e TZ=Europe/Berlin \
  -e PILER_RETENTION=3650 \
  -e PILER_HOST=piler.yourdomain.com \
  -e MYSQL_DATABASE=piler \
  -e MYSQL_USER=piler-db-user \
  -e MYSQL_PASSWORD=piler123 \
  -e MARIADB_ROOT_PASSWORD=enter-very-secure-root-pw \
  -p 80:80 \
  -p 443:443 \
  -p 25:25 \
  -v piler-data-store:/var/piler/store/00 \
  -v piler-data-sphinx:/var/piler/sphinx \
  -v piler-data-config:/etc/piler \
  -v piler-data-mariadb:/var/lib/mysql \
  --restart unless-stopped \
  fabianbees/mail-piler:latest
```


⚠️⚠️ **IMPORTANT: Bind-Mounts are currently not supported, so you have to use Docker volumes!!** ⚠️⚠️


## Usage via docker-compose

First create a `.env` file to substitute variables for your deployment. 


### Required environment variables


| Docker Environment Var | Description|
| --- | --- |
| `PILER_RETENTION`<br/> | Retention time
| `PILER_HOST`<br/> | Piler FQDN
| `MYSQL_DATABASE`<br/> | MariaDB database name
| `MYSQL_USER`<br/> | MariaDB database user
| `MYSQL_PASSWORD`<br/> | MariaDB database pw
| `MARIADB_ROOT_PASSWORD`<br/> | MariaDB root pw


Example `.env` file in the same directory as your `docker-compose.yaml` file:

```
PILER_RETENTION=3650
PILER_HOST=piler.yourdomain.com
MYSQL_DATABASE=piler
MYSQL_USER=piler-db-user
MYSQL_PASSWORD=piler123
MARIADB_ROOT_PASSWORD=enter-very-secure-root-pw
```


### Running the stack with docker compose

```bash
docker-compose up -d
```

> If using Portainer, just paste the `docker-compose.yaml` contents into the stack config and add your *environment variables* directly in the UI.


### Database Upgrade (manual step!)

> The mail-piler container must be stopped during this operation !!!

If you get an error that your database needs to be upgraded, you must do this manually by the following steps:

1. Run the database with the old database image and shut it down gracefully:

for example: 
```
docker run -d \
  --name=db-upgrade \
  -e MYSQL_DATABASE=piler \
  -e MYSQL_USER=piler-db-user \
  -e MYSQL_PASSWORD=piler123 \
  -e MARIADB_ROOT_PASSWORD=enter-very-secure-root-pw \
  -v piler-data-mariadb:/var/lib/mysql \
  mariadb:10.6-focal
```

2. After the gracefull shutdown the new image can be used with the parameter ```-e MARIADB_AUTO_UPGRADE=true```.
This starts an automatic update.
After that shutdown this temporary container and you can restart the mail-piler container.

for example: 
```
docker run -d \
  --name=db-upgrade \
  -e MYSQL_DATABASE=piler \
  -e MYSQL_USER=piler-db-user \
  -e MYSQL_PASSWORD=piler123 \
  -e MARIADB_ROOT_PASSWORD=enter-very-secure-root-pw \
  -v piler-data-mariadb:/var/lib/mysql \
  -e MARIADB_AUTO_UPGRADE=true \
  mariadb:10.10-jammy
```
