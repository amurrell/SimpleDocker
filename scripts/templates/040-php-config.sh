#!/usr/bin/env bash

printf "============ Script: PHP Config\n"

PHP_VERSION=$(cat /var/www/LEMP-setup-guide/config/versions/php-version)
# if override-php-version is set, use that
if [ -f "/var/www/LEMP-setup-guide/config/versions/override-php-version" ]; then
    PHP_VERSION=$(cat /var/www/LEMP-setup-guide/config/versions/override-php-version)
fi
PHPINI="/etc/php/$PHP_VERSION/fpm/php.ini"

## Adjust INI
printf "============ Adjust PHP ini - upload max size\n"
if [ -f "$PHPINI" ]; then
  sudo sed -i "/;upload_max_filesize = .*/c\upload_max_filesize = 20M" $PHPINI
  sudo sed -i "/upload_max_filesize = .*/c\upload_max_filesize = 20M" $PHPINI
  sudo sed -i "/;post_max_size = .*/c\post_max_size = 64M" $PHPINI
  sudo sed -i "/post_max_size = .*/c\post_max_size = 64M" $PHPINI
  sudo sed -i "/;memory_limit = .*/c\memory_limit = 256M" $PHPINI
  sudo sed -i "/memory_limit = .*/c\memory_limit = 256M" $PHPINI
fi

