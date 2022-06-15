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
    
RUN apk add --no-cache libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*