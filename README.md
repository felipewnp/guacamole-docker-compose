# Guacamole with Docker Compose
This is a small documentation explaining how to run a fully working **Apache Guacamole** instance with Docker (Docker Compose).

The goal of this project is to make it easy to test Guacamole.

## About Guacamole
Apache Guacamole is a clientless remote desktop gateway. It supports standard protocols like VNC, RDP, and SSH. It is called clientless because no plugins or client software are required. Thanks to HTML5, once Guacamole is installed on a server, all you need to access your desktops is a web browser.

It supports RDP, SSH, Telnet, and VNC and is the fastest HTML5 gateway I know. Check out the project's [homepage](https://guacamole.apache.org/) for more information.

## Prerequisites
You need a working **Docker** installation and **Docker Compose** running on your machine.

## Quick start
Clone the Git repository and start Guacamole:

~~~bash
git clone "https://github.com/felipewnp/guacamole-docker-compose.git"
cd guacamole-docker-compose
./prepare.sh
docker compose up -d
~~~

Your Guacamole server should now be available at `https://<IP of your server>:8443/`.  

The default username is `guacadmin` with password `guacadmin`.

## Details
To understand some details, let's take a closer look at parts of the `docker-compose.yml` file:

### Networking
The following part of `docker-compose.yml` uses a previously configured network named `services-network` in `external` mode.

To create this network, run `docker network create --driver bridge services-network`.

~~~python
...
# networks
# Uses a previously configured network called 'services-network'
networks:
  services-network:
    external: true
...
~~~

### Services
#### guacd
The following part of `docker-compose.yml` creates the `guacd` service. `guacd` is the heart of Guacamole; it dynamically loads support for remote desktop protocols (called "client plugins") and connects them to remote desktops based on instructions received from the web application. The container is called `guacd`, based on the Docker image `guacamole/guacd`, and is connected to the previously created network `services-network`. Additionally, two local folders, `/home/guacamole_stack/guacd/drive` and `/home/guacamole_stack/guacd/record`, are mapped into the container. They can be used later to map user drives and store session recordings.

~~~python
...
guacd:
  container_name: guacd
  image: guacamole/guacd:1.6.0
  restart: always
  networks:
    - services-network
  volumes:
  - /home/guacamole_stack/guacd/drive:/drive:rw
  - /home/guacamole_stack/guacd/record:/record:rw
...
~~~

#### MySQL
The following part of `docker-compose.yml` creates an instance of MariaDB (MySQL-compatible) using the official Docker image. This image is highly configurable using environment variables. For example, it initializes a database if an initialization script is found in the directory `/docker-entrypoint-initdb.d` within the container. Since the local folder `./init` is mapped to `docker-entrypoint-initdb.d`, the Guacamole database can be initialized using a custom script (`/home/guacamole_stack/db/init/initdb.sql`). You can read more about the official MariaDB image in its documentation.

~~~python
...
guacamole_db:
  container_name: guacamole_db
  image: mariadb:12.1.2-noble
  restart: always
  networks:
    - services-network
  environment:
    MYSQL_DATABASE: guacamole_db
    MYSQL_ROOT_PASSWORD: 'ChooseYourOwnPasswordHere1234'
    MYSQL_PASSWORD: 'ChooseYourOwnPasswordHere1234'
    MYSQL_USER: guacamole_user
  volumes:
    - /home/docker/guacamole_stack/db/init:/docker-entrypoint-initdb.d:z
    - /home/docker/guacamole_stack/db/data:/var/lib/mysql
...
~~~

#### Guacamole
The following part of `docker-compose.yml` creates an instance of Guacamole using the Docker image `guacamole/guacamole` from Docker Hub. It is also highly configurable using environment variables. In this setup, it is configured to connect to the previously created MySQL instance using a username, password, and the database `guacamole_db`. Port 8080 is exposed only locally; npm-plus is used to expose it externally.

~~~python
...
guacamole:
  container_name: guacamole
  image: guacamole/guacamole:1.6.0
  restart: always
  networks:
    - services-network
  # ports:
  #   - 8080:8080/tcp # Guacamole is on :8080/guacamole, not /
  group_add:
    - "1000"
  depends_on:
    - guacd
    - guacamole_db
  environment:
    GUACD_HOSTNAME: guacd
    MYSQL_DATABASE: guacamole_db
    MYSQL_HOSTNAME: guacamole_db
    MYSQL_PASSWORD: 'ChooseYourOwnPasswordHere1234'
    MYSQL_USER: guacamole_user
    RECORDING_SEARCH_PATH: /record
  volumes:
    - /home/docker/guacamole_stack/guacamole/record:/record:rw
...
~~~

#### npm-plus
The following part of `docker-compose.yml` creates an instance of npm-plus. You should configure the forwarding rules in the npm-plus Web UI.

~~~python
...
npmplus:
  container_name: npmplus
  image: docker.io/zoeyvid/npmplus:latest # or ghcr.io/zoeyvid/npmplus:latest
  restart: always
  networks:
    - services-network
  ports:
    - "80:80"   # Public HTTP port
    - "443:443" # Public HTTPS port
    - "81:81"   # Admin web port
  environment:
    - "TZ=America/Sao_Paulo" # Set timezone (required). Use a valid TZ identifier.
    - "ACME_EMAIL=your@email.domain" # Email address used for ACME registration
    - "ACME_KEY_TYPE=ecdsa" # Key type to use: ecdsa or rsa (default and recommended: ecdsa)
  volumes:
    - "/home/docker/npmplus/data:/data"
...
~~~

## prepare.sh
`prepare.sh` is a small script that creates `/home/docker/guacamole_stack/db/init/initdb.sql` by downloading the Docker image `guacamole/guacamole` and starting it as follows:

~~~bash
docker run --rm 'guacamole/guacamole:1.6.0' /opt/guacamole/bin/initdb.sh --mysql > /home/docker/guacamole_stack/db/init/initdb.sql
~~~

It creates the necessary database initialization file for MySQL.

## reset.sh
To reset everything to the initial state, simply run `./reset.sh`.

## WOL
Wake-on-LAN was not tested in this release, and I cannot confirm whether it works or not.

## Disclaimer

Downloading and executing scripts from the internet may harm your computer. Make sure to review the source of any script before executing it.
