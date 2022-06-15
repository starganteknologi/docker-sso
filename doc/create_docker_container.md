# create docker container

## create file docker-compose.yml

make sure to attach local files to container with volume options 

``` yml
version: '3.9'
services:
    web:
        image: nginx:latest
        ports:
            - "4443:443"
        volumes:
            - ./certs:/etc/ssl/certs
            - ./volumes/nginx/config/nginx.conf:/etc/nginx/conf.d/nginx.conf
            - ./volumes/nginx/config/self-signed.conf:/etc/nginx/conf.d/self-signed.conf
            - ./volumes/nginx/config/ssl-params.conf:/etc/nginx/conf.d/ssl-params.conf
            - ./volumes/sites:/sites
        links:
            - php
    php:
        build:
            context: .
            dockerfile: PHP.Dockerfile
            args:
                buildno: 1
        volumes:
            - ./volumes/sites:/sites
        depends_on:
            - postgres
    postgres:
        image: postgres:14-alpine
        ports:
            - '15432:5432'
        environment:
            POSTGRES_HOST_AUTH_METHOD: trust
            POSTGRES_USER: ${POSTGRES_USER}
            POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
            POSTGRES_DB: main
        volumes:
            - ./volumes/postgres/docker-entrypoint-initdb.d:/docker-entrypoint-initdb.d
            - ./volumes/postgres/postgres-data:/var/lib/postgresql/data
            - ./volumes/postgres/postgres-backup:/var/lib/postgresql/backup
volumes:
    pgdata: {}
```

## create ```PHP.dockerfile ```

``` dockerfile
FROM php:8.1-fpm-alpine

ARG buildno
ARG gitcommithash

RUN echo "Build number: $buildno"
RUN echo "Based on commit: $gitcommithash"
ENV ACCEPT_EULA=Y
# Fix debconf warnings upon build
ARG DEBIAN_FRONTEND=noninteractive

RUN apk add --no-cache \
    icu-dev \ 
    g++ \
    libressl \
    gnupg \
    zlib-dev \
    oniguruma-dev \
    libmcrypt-dev \
    libpng-dev \ 
    autoconf \
    make \
    unixodbc-dev

RUN docker-php-ext-install mbstring \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug

RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install ldap; \
    docker-php-ext-install bcmath

RUN docker-php-ext-configure intl && docker-php-ext-install intl
    
RUN docker-php-ext-install pdo pdo_pgsql pgsql; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*
```