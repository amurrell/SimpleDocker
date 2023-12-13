#!/usr/bin/env bash

printf "============ Script: Deploy example.com with deploy.sh\n"

# replace these!

DOMAIN='example.com'
REPO='GITHUB_USER/REPO_NAME'
BRANCH='main'

cd ~/

# detect we have a deploy.sh file - note: cannot do a -f on ~/
if [ ! -f "deploy.sh" ]; then
    printf "============ No deploy.sh file found in home directory. Exiting.\n"
    exit 1
fi

# source .bashrc for node
printf "============ Source bash profile again to ensure node access\n"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
source ~/.bashrc

###### CUSTOM STUFF

# try to make sure pm2 is started with this ecosystem file
printf "============ Try to make sure pm2 is started /var/www/$DOMAIN/ecosystem.config.js file\n"
# if ecosystem.config.js exists, then pm2 start
if [ -f "/var/www/$DOMAIN/ecosystem.config.js" ]; then
    cd /var/www/$DOMAIN
    pm2 start
fi

# Run deploy.sh to try deploying 
printf "============ Running deploy.sh --repo $REPO --branch $BRANCH to try deploying...\n"
cd ~/
./deploy.sh --repo $REPO --branch $BRANCH

# try to run pm2 again - the server may not have been running or built yet when we tried earlier.
printf "============ Try to make sure pm2 is started /var/www/$DOMAIN/ecosystem.config.js file\n"
# if ecosystem.config.js exists, then pm2 start
if [ -f "/var/www/$DOMAIN/ecosystem.config.js" ]; then
    cd /var/www/$DOMAIN
    pm2 start
fi