#!/bin/bash

# If APP_HOSTNAME is not set, use default `hostname`
APP_HOSTNAME=${WEBSITE_HOSTNAME}

_good "nginx:  server_name ${APP_HOSTNAME}"
sed -i -r "s/example.com/${APP_HOSTNAME}/g" /etc/nginx/server.d/10_pagespeed.conf

# Prevent config files from being filled to infinity by force of stop and restart the container
lastlinephpconf="$(grep "." /usr/local/etc/php-fpm.conf | tail -1)"
if [[ $lastlinephpconf == *"php_flag[display_errors]"* ]]; then
 sed -i '$ d' /usr/local/etc/php-fpm.conf
fi

# Display PHP error's or not
if [[ "$ERRORS" != "1" ]] ; then
 echo php_flag[display_errors] = off >> /usr/local/etc/php-fpm.conf
else
 echo php_flag[display_errors] = on >> /usr/local/etc/php-fpm.conf
fi

# Pass real-ip to logs when behind ELB, etc
if [[ "$REAL_IP_HEADER" == "1" ]] ; then
 sed -i "s/#real_ip_header X-Forwarded-For;/real_ip_header X-Forwarded-For;/" /etc/nginx/sites-available/default.conf
 sed -i "s/#set_real_ip_from/set_real_ip_from/" /etc/nginx/sites-available/default.conf
 if [ ! -z "$REAL_IP_FROM" ]; then
  sed -i "s#172.16.0.0/12#$REAL_IP_FROM#" /etc/nginx/sites-available/default.conf
 fi
fi

 Configure pagespeed to support downstream caching
# See: https://modpagespeed.com/doc/downstream-caching
if [ "${PAGESPEED_REBEACON_KEY}" = "$DEFAULT_PAGESPEED_REBEACON_KEY" ]; then
    _warning "nginx:  Pagespeed rebeacon key is default, please change \$PAGESPEED_REBEACON_KEY"
else
    _good "nginx:  PAGESPEED_REBEACON_KEY $PAGESPEED_REBEACON_KEY"
fi
sed -i -r "s/DownstreamCacheRebeaconingKey \"__PAGESPEED_REBEACON_KEY__\";/DownstreamCacheRebeaconingKey \"${PAGESPEED_REBEACON_KEY:-$DEFAULT_PAGESPEED_REBEACON_KEY}\";/g" /etc/nginx/server.d/10_pagespeed.conf



# Increase the memory_limit
if [ ! -z "$PHP_MEM_LIMIT" ]; then
 sed -i "s/memory_limit = 128M/memory_limit = ${PHP_MEM_LIMIT}M/g" /usr/local/etc/php/conf.d/docker-vars.ini
fi

# Increase the post_max_size
if [ ! -z "$PHP_POST_MAX_SIZE" ]; then
 sed -i "s/post_max_size = 100M/post_max_size = ${PHP_POST_MAX_SIZE}M/g" /usr/local/etc/php/conf.d/docker-vars.ini
fi

# Increase the upload_max_filesize
if [ ! -z "$PHP_UPLOAD_MAX_FILESIZE" ]; then
 sed -i "s/upload_max_filesize = 100M/upload_max_filesize= ${PHP_UPLOAD_MAX_FILESIZE}M/g" /usr/local/etc/php/conf.d/docker-vars.ini
fi

if [ ! -z "$PUID" ]; then
  if [ -z "$PGID" ]; then
    PGID=${PUID}
  fi
  deluser nginx
  addgroup -g ${PGID} nginx
  adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx -u ${PUID} nginx
else
  if [ -z "$SKIP_CHOWN" ]; then
    chown -Rf nginx.nginx /var/www/html
  fi
fi

/app/bin/cloudflare-ip-updater.sh
# Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
