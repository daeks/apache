FROM debian:buster-slim
LABEL maintainer="github.com/daeks"

ENV GIT OFF
ENV GIT_TOKEN <token>
ENV GIT_URL https://$GIT_TOKEN@github.com/<user>/<repo>.git

ENV HTTP_PORT 80
ENV HTTPS_PORT 443

ENV TIMEZONE Europe/Berlin


ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data

ENV APACHE_WWW_DIR /var/www
ENV APACHE_CONF_DIR=/etc/apache2
ENV APACHE_CONFDIR $APACHE_CONF_DIR
ENV APACHE_ENVVARS $APACHE_CONF_DIR/envvars

ENV APACHE_CUSTOM_DIR $APACHE_CONF_DIR/custom
ENV APACHE_OPT_DIR $APACHE_CUSTOM_DIR/opt
ENV APACHE_VHOSTS_DIR $APACHE_CUSTOM_DIR/vhosts
ENV APACHE_SVHOSTS_DIR $APACHE_CUSTOM_DIR/svhosts

ENV APACHE_RUN_DIR /var/run
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE $APACHE_RUN_DIR/apache2.pid
ENV LANG C

ENV PHP_VER=7.3
ENV PHP_CONF_DIR=/etc/php/$PHP_VER
ENV PHP_DATA_DIR=/var/lib/php

ENV CERTBOT_CONF_DIR /etc/letsencrypt
ENV CERTBOT_WORK_DIR /var/lib/letsencrypt
ENV CERTBOT_LOG_DIR /var/log/letsencrypt

ENV DEBIAN_FRONTEND noninteractive

RUN set -x &&\
  apt-get update && apt-get -y upgrade &&\
  apt-get install -y --no-install-recommends --no-install-suggests \
    procps curl nano rsyslog cron ca-certificates openssl git apache2 php$PHP_VER php$PHP_VER-apcu libapache2-mod-php$PHP_VER certbot &&\
  mkdir -p $APACHE_RUN_DIR $APACHE_LOCK_DIR $APACHE_LOG_DIR

RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone

RUN a2enmod php$PHP_VER

RUN set -x &&\
  sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" $PHP_CONF_DIR/apache2/php.ini &&\
  rm $APACHE_CONF_DIR/sites-enabled/000-default.conf $APACHE_CONF_DIR/sites-available/000-default.conf &&\
  rm $APACHE_CONF_DIR/sites-available/default-ssl.conf &&\
  rm -r $APACHE_WWW_DIR/html &&\
  mkdir -p $APACHE_CUSTOM_DIR && mkdir -p $APACHE_OPT_DIR && mkdir -p $APACHE_VHOSTS_DIR && mkdir -p $APACHE_SVHOSTS_DIR &&\
  ln -sf /dev/stdout /var/log/apache2/access.log &&\
  ln -sf /dev/stderr /var/log/apache2/error.log &&\
  chown $APACHE_RUN_USER:$APACHE_RUN_GROUP $PHP_DATA_DIR -Rf

COPY ./configs/apache2.conf $APACHE_CONF_DIR/apache2.conf
COPY ./configs/ports.conf $APACHE_CONF_DIR/ports.conf

COPY ./configs/custom-default.conf $APACHE_CONF_DIR/sites-available/000-custom-default.conf
COPY ./configs/custom-default-redirect.conf $APACHE_CONF_DIR/sites-available/000-custom-default-redirect.conf
COPY ./configs/custom-default-ssl.conf $APACHE_CONF_DIR/sites-available/000-custom-default-ssl.conf

COPY ./configs/php.ini $PHP_CONF_DIR/apache2/conf.d/custom.ini
COPY ./configs/php.ini $PHP_CONF_DIR/cli/conf.d/custom.ini

COPY ./apache.sh /apache.sh
RUN chmod +x /apache.sh

COPY ./status.sh /status.sh
RUN chmod +x /status.sh

RUN set -x &&\
  apt-get clean autoclean &&\
  apt-get autoremove -y &&\
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*^
  
HEALTHCHECK CMD /status.sh

#USERNAME $APACHE_RUN_USER
WORKDIR $APACHE_WWW_DIR
VOLUME $APACHE_WWW_DIR

ENTRYPOINT /apache.sh

EXPOSE $HTTP_PORT/tcp $HTTPS_PORT/tcp 
