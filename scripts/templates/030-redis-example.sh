#!/usr/bin/env bash

# Install Server Specific

###############################

printf "============ Script: Redis SimpleDocker Example\n"

# Vars

# Change this path to your own config
REDIS_CONF=$(</var/www/simple-docker/scripts/templates/redis-example.conf)
REDIS_CONF_PATH='/etc/redis/redis.conf'

## Install Redis Server
printf "============ Install Redis Server\n"
cd /var/www/LEMP-setup-guide/install/components/redis
./install

# Add the custoer server redis config
printf "============ Install Custom Server Config for Redis\n"
if [ -f "$REDIS_CONF_PATH" ]; then
    # replace/create file
    echo "$REDIS_CONF" > "$REDIS_CONF_PATH"
else
    # append to file
    echo "$REDIS_CONF" >> "$REDIS_CONF_PATH"
fi

# Restart, bc of possible config changes
printf "============ Start Redis Service\n"
# if directory simple-docker exists
if [ -d "/var/www/simple-docker" ]; then
    sudo service redis-server start &
else
    sudo systemctl start redis-server.service
fi
