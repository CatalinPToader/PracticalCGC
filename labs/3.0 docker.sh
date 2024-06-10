#!/bin/bash

read_input() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt ($default): " input
    echo "${input:-$default}"
}

DNS_IP=$(read_input "Enter the IP address of your DNS server" "192.168.100.11")
MYSQL_ROOT_PASSWORD=$(read_input "Enter the MySQL root password" "somewordpress")
MYSQL_DATABASE=$(read_input "Enter the MySQL database name" "wordpress")
MYSQL_USER=$(read_input "Enter the MySQL username" "wordpress")
MYSQL_PASSWORD=$(read_input "Enter the MySQL password" "wordpress")

cat << EOF > Dockerfile.centos
FROM gitlab.cs.pub.ro:5050/scgc/cloud-courses/centos:7

ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NONINTERACTIVE_SEEN=true

RUN yum update -y
RUN yum install -y bind-utils
EOF

docker build -t centos-bind-utils -f Dockerfile.centos .

docker run --rm centos-bind-utils nslookup hub.docker.com

cat << EOF > docker-compose.yml
version: "3.3"

services:
  nextcloud:
    image: nextcloud
    ports:
      - "8000:80"
    volumes:
      - nextcloud-vol:/var/www/html

volumes:
  nextcloud-vol:
EOF

docker-compose up -d

docker stop nextcloud
docker rm nextcloud
docker run -d --name nextcloud -v nextcloud-vol:/var/www/html nextcloud

docker exec -it nextcloud bash -c "ls /var/www/html"

# Step 7: Set up MySQL and WordPress containers using Docker Compose
cat << EOF > docker-compose-wordpress.yml
version: "3.3"

services:
  db:
    image: mysql:5.7
    networks:
      - wordpress-net
    volumes:
      - mysql-vol:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    networks:
      - wordpress-net
    ports:
      - "8000:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}

volumes:
  mysql-vol:

networks:
  wordpress-net:
EOF

docker-compose -f docker-compose-wordpress.yml up -d