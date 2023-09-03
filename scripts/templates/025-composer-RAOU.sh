#!/usr/bin/env bash

# Install Server Specific

###############################

# store whoami in a variable
CURRENT_USER=$(whoami)

# Install Server Specific

###############################

OWNER_USER='ubuntu'

# if owner_user is not current_user, exit
if [ "$CURRENT_USER" != "$OWNER_USER" ]; then
    printf "============ Current user is not $OWNER_USER, exiting\n"
    exit 1
fi

## Composer via LEMP-setup-guide
printf "============ Run as $OWNER_USER: Install composer\n"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/home/ubuntu --filename=composer

# Export /home/ubuntu to $PATH so composer is available
printf "============ Run as $OWNER_USER: Export /home/$OWNER_USER to \$PATH so composer is available\n"
echo -e "\nexport PATH=/home/$OWNER_USER:\$PATH\n" >> /home/$OWNER_USER/.bashrc
export PATH=/home/$OWNER_USER:$PATH
source /home/$OWNER_USER/.bashrc
