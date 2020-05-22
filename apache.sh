#!/bin/bash

if [ -f $APACHE_CUSTOM_DIR/crontab ]; then
  crontab $APACHE_CUSTOM_DIR/crontab
  service rsyslog start && service cron start
fi

if [ -f $APACHE_CUSTOM_DIR/extension ]; then
  source $APACHE_CUSTOM_DIR/extension
fi

if [ ! -z "$DOMAIN" ] && [ ! -z "$EMAIL" ]; then
  if [ ! -f $CERTBOT_CONF_DIR/live/$DOMAIN/cert.pem ]; then
    certbot certonly --no-self-upgrade --agree-tos --noninteractive --standalone \
      --work-dir $CERTBOT_WORK_DIR --config-dir $CERTBOT_CONF_DIR --logs-dir $CERTBOT_LOG_DIR \
      -m $EMAIL -d $DOMAIN
    
    if [ -f $CERTBOT_CONF_DIR/live/$DOMAIN/cert.pem ]; then
      a2dissite 000-custom-default
      rm -f $APACHE_CONF_DIR/sites-available/000-custom-default.conf
    
      a2enmod rewrite && a2enmod ssl
      
      a2dissite default-ssl
      rm -f $APACHE_CONF_DIR/sites-available/default-ssl.conf
      
      a2ensite 000-custom-default-redirect
      a2ensite 000-custom-default-ssl
    else
      a2ensite 000-custom-default
    fi
  else
    flags=""
    if [ ! -z $FORCE_RENEWAL ]; then
      flags="$flags --force-renewal"
    fi
  
    certbot renew --no-random-sleep-on-renew --standalone --no-self-upgrade \
      --work-dir $CERTBOT_WORK_DIR --config-dir $CERTBOT_CONF_DIR --logs-dir $CERTBOT_LOG_DIR $flags
  fi
else
  a2ensite 000-custom-default
fi

if [ "$GIT" != "OFF" ]; then
  if [ -d "$APACHE_WWW_DIR/.git" ]; then
    git fetch --all origin
    git reset --hard origin/master
    git pull
  else
    git clone $GIT_URL $APACHE_WWW_DIR/
    chown -R $APACHE_RUN_USER:$APACHE_RUN_USER $APACHE_WWW_DIR/
    chmod -R 744 $APACHE_WWW_DIR
  fi
fi

/usr/sbin/apache2 -D FOREGROUND
