#!/bin/bash

# Запуск Nginx
/usr/sbin/nginx -g 'daemon off;' &

# Обновление сертификатов
while true; do
  certbot renew
  nginx -s reload
  sleep 12h & wait $!
done
