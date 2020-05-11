FROM debian:buster-slim
LABEL maintainer="github.com/daeks"

ENV GIT OFF
ENV GIT_TOKEN <token>
ENV GIT_URL https://$GIT_TOKEN:x-oauth-basic@github.com/<user>/<repo>.git

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data

ENV APACHE_WWW_DIR /var/www
ENV APACHE_CONF_DIR=/etc/apache2

ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

ENV PHP_VER=7.3
ENV PHP_CONF_DIR=/etc/php/$PHP_VER
ENV PHP_DATA_DIR=/var/lib/php

ENV DEBIAN_FRONTEND noninteractive

RUN set -x &&\
  apt-get update && apt-get -y upgrade &&\
  apt-get install -y --no-install-recommends --no-install-suggests \
    locales rsyslog cron ca-certificates openssl git apache2 php$PHP_VER libapache2-mod-php$PHP_VER curl
  
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8

RUN a2enmod php$PHP_VER

RUN set -x &&\
  sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" $PHP_CONF_DIR/apache2/php.ini &&\
  rm ${APACHE_CONF_DIR}/sites-enabled/000-default.conf ${APACHE_CONF_DIR}/sites-available/000-default.conf &&\
  rm -r ${APACHE_WWW_DIR}/html &&\
  ln -sf /dev/stdout /var/log/apache2/access.log &&\
  ln -sf /dev/stderr /var/log/apache2/error.log &&\
  chown $APACHE_RUN_USER:$APACHE_RUN_USER ${PHP_DATA_DIR} -Rf

COPY ./configs/apache2.conf ${APACHE_CONF_DIR}/apache2.conf
COPY ./configs/virtualhost.conf ${APACHE_CONF_DIR}/sites-enabled/app.conf
COPY ./configs/php.ini ${PHP_CONF_DIR}/apache2/conf.d/custom.ini
COPY ./configs/php.ini ${PHP_CONF_DIR}/cli/conf.d/custom.ini

COPY ./scripts /tmp$APACHE_WWW_DIR
RUN if [ "$GIT" = "OFF" ]; then mv -f /tmp$APACHE_WWW_DIR/* $APACHE_WWW_DIR; fi
RUN if [ "$GIT" != "OFF" ]; then git clone $GIT_URL $APACHE_WWW_DIR/; fi

COPY ./configs/crontab /etc/cron/crontab
RUN crontab /etc/cron/crontab
RUN service rsyslog start && service cron start

RUN set -x &&\
  apt-get clean autoclean &&\
  apt-get autoremove -y &&\
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*^
  
HEALTHCHECK CMD curl -f http://localhost/ || exit 1

WORKDIR $APACHE_WWW_DIR
VOLUME $APACHE_WWW_DIR

ENTRYPOINT /usr/sbin/apache2 -D FOREGROUND

EXPOSE 80