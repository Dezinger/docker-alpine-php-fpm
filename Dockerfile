FROM alpine:3.10

ARG WEB_DOCUMENT_ROOT="/var/www"
ARG COMPOSER_VER="1.9.3"

ENV \
    COMPOSER_ALLOW_SUPERUSER="1" \
    COMPOSER_HOME="/tmp/composer" \
# Color console
    PS1='\[\033[1;32m\]\[\033[1;36m\][\u@\h] \[\033[1;34m\]\w\[\033[0;35m\] \[\033[1;36m\]# \[\033[0m\]'

# ensure www-data user exists
RUN set -eux; \
	addgroup -g 82 -S www-data; \
	adduser -u 82 -D -S -G www-data www-data
# 82 is the standard uid/gid for "www-data" in Alpine
# https://git.alpinelinux.org/aports/tree/main/apache2/apache2.pre-install?h=3.9-stable
# https://git.alpinelinux.org/aports/tree/main/lighttpd/lighttpd.pre-install?h=3.9-stable
# https://git.alpinelinux.org/aports/tree/main/nginx/nginx.pre-install?h=3.9-stable

RUN set -xe \
# Install packages
    && apk --no-cache add \
        php7 \
        php7-fpm \
        php7-json \
        php7-openssl \
        php7-phar \
        php7-ctype \
        php7-exif \
        php7-fileinfo \
        php7-ftp \
        php7-gettext \
        php7-iconv \
        php7-pcntl \
        php7-pgsql \
        php7-pdo \
        php7-pdo_pgsql \
        php7-posix \
        php7-sodium \
        php7-opcache \
        php7-curl \
        php7-common \
        php7-gd \
        php7-xsl \
        php7-xmlrpc \
        php7-tidy \
        php7-memcached \
        php7-imagick \
        php7-intl \
        php7-mbstring \
        php7-msgpack \
        php7-zip \
        php7-soap \
        php7-bcmath \
        php7-mcrypt \
        php7-xmlwriter \
        php7-xmlreader \
        php7-wddx \
        php7-tokenizer \
        php7-sysvmsg \
        php7-sysvsem \
        php7-sysvshm \
# Setup composer and global libs
    && php -r "readfile('http://getcomposer.org/installer');" | \
    php -- --install-dir=/usr/local/bin/ --version=${COMPOSER_VER} --filename=composer \
    && chmod a+x /usr/local/bin/composer \
    && composer global require 'hirak/prestissimo' 'fxp/composer-asset-plugin:~1.4' --no-interaction --no-suggest --prefer-dist \
    && ln -s /usr/bin/composer /usr/bin/c \
# Clean
    && rm -rf ${WEB_DOCUMENT_ROOT} /home/user ${COMPOSER_HOME} /var/cache/apk/* \
# Prepare folders
    && mkdir ${WEB_DOCUMENT_ROOT} /home/user ${COMPOSER_HOME} \
    && chown www-data:www-data ${WEB_DOCUMENT_ROOT}

WORKDIR ${WEB_DOCUMENT_ROOT}

COPY files/ /

RUN set -xe \
    && chmod +x /usr/local/bin/docker-entrypoint \
    && composer --version \
    && php -v \
    && php -m

VOLUME ["$WEB_DOCUMENT_ROOT"]

ENTRYPOINT ["docker-entrypoint"]

# Override stop signal to stop process gracefully
# https://github.com/php/php-src/blob/17baa87faddc2550def3ae7314236826bc1b1398/sapi/fpm/php-fpm.8.in#L163
STOPSIGNAL SIGQUIT

EXPOSE 9000

CMD ["php-fpm7"]