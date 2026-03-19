# Базовый образ Nginx
FROM nginx:stable-bookworm

# Установка необходимых пакетов
RUN apt-get update && apt-get install -y \
    certbot \
    python3-certbot-nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Создание необхомых дирректорий
RUN mkdir /var/nginx; \
    mkdir /var/nginx/client_body_temp; \
    mkdir /var/nginx/proxy_temp; \
    mkdir /var/www; \
    mkdir /var/www/frontend;

# Копирование SSL сертификатов
COPY ./certbot/letsencrypt /etc/letsencrypt

# Копирование конфигурации Nginx
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./default.conf /etc/nginx/conf.d/default.conf

# Копирование сайта
COPY ./frontend /var/www/frontend

RUN chown root:www-data -R /var/www

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]