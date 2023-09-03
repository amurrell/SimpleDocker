#!/usr/bin/env bash

printf "============ WHO AM I? ============\n"
whoami

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

# Fix issue with bash profile
printf "============ Fix issue with bash profile tty mesg n error for $OWNER_USER\n"
sed -i -e 's/mesg n .*true/tty -s \&\& mesg n/g' "/home/$OWNER_USER/.profile"

# Install nvm - Via LEMP-setup-guide
printf "============ Run as $OWNER_USER: Install nvm\n"
cd /var/www/LEMP-setup-guide/install/components/nvm
./install

# Load nvm
printf "============ Run as $OWNER_USER: Load nvm\n"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Test command nvm exists
printf "============ Run as $OWNER_USER: Test command nvm exists\n"
command -v nvm

# Install npm (nodejs version is used)
printf "============ Run as $OWNER_USER: Install node via nvm - Will look for version in LEMP-Setup-Guide or use default 16.14.2 \n"
# Get NVM_VERSION from /var/www/LEMP-setup-guide/config/versions/override-node-version or node-version
NVM_VERSION_DEFAULT=16.14.2
NVM_VERSION=$(cat /var/www/LEMP-setup-guide/config/versions/node-version)
NVM_VERSION_OVERRIDE=$(cat /var/www/LEMP-setup-guide/config/versions/override-node-version)

if [ -z "$NVM_VERSION" ]; then
    NVM_VERSION=$NVM_VERSION_DEFAULT
fi

if [ ! -z "$NVM_VERSION_OVERRIDE" ]; then
    NVM_VERSION=$NVM_VERSION_OVERRIDE
fi

nvm install $NVM_VERSION

# Install pm2 - Via LEMP-setup-guide
printf "============ Run as $OWNER_USER: Install pm2\n"
cd /var/www/LEMP-setup-guide/install/components/pm2
./install

# Source bash profile
printf "============ Run as $OWNER_USER: Source bash profile\n"
source ~/.bashrc

# Test nvm and pm2 commands
printf "============ Run as $OWNER_USER: Test nvm and pm2 commands\n"
command -v nvm
command -v pm2
