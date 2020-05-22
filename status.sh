#!/bin/bash
if [ ! -z "$DOMAIN" ] && [ ! -z "$EMAIL" ]; then
    if [ ! -f $CERTBOT_CONF_DIR/live/$DOMAIN/cert.pem ]; then
      curl -f http://localhost:$HTTP_PORT/ && curl -f http://$DOMAIN:$HTTP_PORT/ || exit 1
    else
      curl -f http://localhost:$HTTP_PORT/ && curl -f http://$DOMAIN:$HTTP_PORT/ && curl -f https://$DOMAIN:$HTTPS_PORT/ || exit 1
    fi
else
    curl -f http://localhost:$HTTP_PORT/ || exit 1
fi