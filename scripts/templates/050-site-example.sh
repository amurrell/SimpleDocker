#!/usr/bin/env bash

# Install Server Specific

###############################

printf "============ Script: Site Example\n"

# Install Server Specific

###############################

OWNER_USER='ubuntu'
DAEMON_USER='www-data'
SCRIPT_USER='root'
SERVER='example.com'
DOMAIN='example.com'
GITHUB_REPO='https://github.com:amurrell/developer-wordpress.git'
PHP_VERSION=$(cat /var/www/LEMP-setup-guide/config/versions/php-version)
# use for location of keys on prod!
BASE_PATH_DEPLOY_KEYS=/root/devops/config/deployment-keys
DEPLOY_FOLDER=false
WEB_ROOT_PATH='html'

THEMENAME='devwp'
DB_NAME='example_com'
DB_USER='example'
DB_PASS='sadhjfhkdsjhfkjdsf'

# if override-php-version is set, use that
if [ -f "/var/www/LEMP-setup-guide/config/versions/override-php-version" ]; then
    PHP_VERSION=$(cat /var/www/LEMP-setup-guide/config/versions/override-php-version)
fi

# if using simple-docker, deploy keys are found at /var/www/simple-docker/scripts/server-$SERVER/
# if running via devops repo, deploy keys are found at $BASE_PATH_DEPLOY_KEYS/
if [ -f "/var/www/simple-docker/scripts/server-$SERVER/$DOMAIN-deploy_key.pub" ]; then
    DEPLOY_KEY_PUBLIC_FILE=/var/www/simple-docker/scripts/server-$SERVER/$DOMAIN-deploy_key.pub
else
    DEPLOY_KEY_PUBLIC_FILE=$BASE_PATH_DEPLOY_KEYS/$DOMAIN-deploy_key.pub
fi

if [ -f "/var/www/simple-docker/scripts/server-$SERVER/$DOMAIN-deploy_key" ]; then
    DEPLOY_KEY_PRIVATE_FILE=/var/www/simple-docker/scripts/server-$SERVER/$DOMAIN-deploy_key
else
    DEPLOY_KEY_PRIVATE_FILE=$BASE_PATH_DEPLOY_KEYS/$DOMAIN-deploy_key
fi

# This will use the deploy key as also the SERVER_SSH_KEY for repo deploy-commands workflow strategy.
# if DEPLOY_KEY_PUBLIC_FILE is not empty and exists -
if [ -s "$DEPLOY_KEY_PUBLIC_FILE" ]; then
    # if DEPLOY_KEY_PUBLIC_FILE does not exist in the content of authorized_keys file, add it
    printf "============ Add DEPLOY_KEY_PUBLIC_FILE to authorized_keys file of OWNER_USER\n"
    # In case these don't exist...
    su $OWNER_USER -c "mkdir -p /home/$OWNER_USER/.ssh"
    su $OWNER_USER -c "touch /home/$OWNER_USER/.ssh/authorized_keys"
    if ! grep -q "$DEPLOY_KEY_PUBLIC_FILE" /home/$OWNER_USER/.ssh/authorized_keys; then
        cat $DEPLOY_KEY_PUBLIC_FILE >> /home/$OWNER_USER/.ssh/authorized_keys
        # fix permissions on the authorized keys file and ownership to OWNER_USER
        chmod 600 /home/$OWNER_USER/.ssh/authorized_keys
        chown $OWNER_USER:$OWNER_USER /home/$OWNER_USER/.ssh/authorized_keys
    fi
fi

# DETECT Services running - this example needs nginx, php-fpm, and mysql/mariadb
# note that in simple-docker, these might not be started yet, so we need to start them
# but in your production, you probably do not need these.

## detect mariadb or mysql
if [ -f "/etc/init.d/mysql" ]; then
    printf "============ Detected mysql\n"
    MYSQL_SERVICE='mysql'
elif [ -f "/etc/init.d/mariadb" ]; then
    printf "============ Detected mariadb\n"
    MYSQL_SERVICE='mariadb'
else
    printf "============ ❌ Could not detect mysql or mariadb\n"
    exit 1
fi

## Make sure mariadb is running - bc we need it for setup-site
printf "============ Make sure $MYSQL_SERVICE is running - bc we need it for setup-site\n"
sudo service $MYSQL_SERVICE start &

# Make sure nginx is running
printf "============ Make sure nginx is running - bc we need it for setup-site\n"
sudo service nginx start &

# Makr sure php-fpm is running
printf "============ Make sure php-fpm is running - bc we need it for setup-site\n"
sudo service php$PHP_VERSION-fpm start &


## INSTALL Setup-Site
printf "============ Run as $OWNER_USER: Pull changes from LEMP-setup-guide\n"
# execute command as OWNER_USER - pull origin
sudo -u $OWNER_USER bash << EOF
cd /var/www/LEMP-setup-guide/
git pull origin
EOF

printf "============ Run as $SCRIPT_USER: Install Site Example Using Setup-Site\n"
cd /var/www/LEMP-setup-guide/scripts

# Deployment keys trick:
# 1st time you run, cut these out and answer prompts to generate keys
# - add to github, and store contents (from logs) into files in this servers' scripts folder.
#   --deploy-key-public-file=$DEPLOY_KEY_PUBLIC_FILE \
#   --deploy-key-private-file=$DEPLOY_KEY_PRIVATE_FILE \
# or use public repo with https: to avoid needing keys or being prompted for ssh password

# with simple docker testing - use these values - or leave them out to use defaults from setup-site
# --nginx-site-conf-path=/var/www/simple-docker/scripts/templates/site.nginx.conf \
# --php-site-conf-path=/var/www/simple-docker/scripts/templates/site.php-fpm.conf \

./setup-site \
  --domain=$DOMAIN \
  --owner-user=$OWNER_USER \
  --github=$GITHUB_REPO \
  --deploy-subfolder=$DEPLOY_FOLDER \
  --web-root-path=$WEB_ROOT_PATH \
  --php-pools=true \
  --nginx-with-php=true \
  --php-with-mysql=true \
  --mysql-create-db=true \
  --mysql-root-user=root \
  --mysql-root-pass=password \
  --database-name=$DB_NAME \
  --database-user=$DB_USER \
  --database-pass=$DB_PASS \
  --database-host=localhost \
  --database-port=3306

if [ $? -ne 0 ]; then
    printf "============ ❌ Script - Site Example Failed\n"
    exit 1
fi

# do developer wordpress setup things

# specific to developer-wordpress in this example. Remove this!
# install wordpress if no /var/www/$DOMAIN/html/wp folder exists
if [ ! -d "/var/www/$DOMAIN/html/wp" ]; then
    printf "============ Install Wordpress\n"
    cd /var/www/$DOMAIN/html
    curl -O -L http://wordpress.org/latest.zip
    unzip latest.zip
    mv wordpress wp
    rm latest.zip
fi

# each site needs deploy-commands repo
printf "============ Installing deploy-commands repo in /var/www/$DOMAIN\n"
cd /var/www/$DOMAIN
git clone https://github.com/amurrell/deploy-commands.git

# wordpress deploy
# if /var/www/deploy-commands/wordpress-deploy exists, ln -s to /var/www/$DOMAIN/commands
if [ -d "/var/www/$DOMAIN/deploy-commands/wordpress-deploy" ]; then
    printf "============ /var/www/$DOMAIN/deploy-commands/wordpress-deploy exists so, ln -s to /var/www/$DOMAIN/commands\n"
    ln -s /var/www/$DOMAIN/deploy-commands/wordpress-deploy /var/www/$DOMAIN/commands

    # add configuration files to this commands folder
    printf "============ Add configuration files to this commands folder\n"
    echo "DockerLocal/logs" > /var/www/$DOMAIN/commands/logsfolder
    echo "html/wp-content/themes/$THEMENAME" > /var/www/$DOMAIN/commands/assetsfolder

    # set OWNER_USER and OWNER_GROUP
    echo "$OWNER_USER" > /var/www/$DOMAIN/commands/owner_user
    echo "$DAEMON_USER" > /var/www/$DOMAIN/commands/owner_group

    # need to setup config file apprepo - but make sure we get it with it's special alias
    # Extract the repository name out of GITHUB_REPO
    REPO_NAME=${GITHUB_REPO##*/}
    REPO_NAME=${REPO_NAME%.git}
    MODIFIED_REPO=${GITHUB_REPO/:/-${REPO_NAME}:}
    echo $MODIFIED_REPO > /var/www/$DOMAIN/commands/apprepo

    # Example scripts can all be made into real scripts
    # check if there are any files starting with example_
    printf "============ Check if there are any bash scripts starting with example_\n"
    cd /var/www/$DOMAIN/commands
    if ls example_* 1> /dev/null 2>&1; then
        printf "============ Found example_ scripts, copying them to scripts without the prefix.\n"
        for file in example_*; do
            cp "$file" "${file#example_}"
            chmod +x "${file#example_}"
        done
    fi

    # mkdir for uploads - or copy a zip here in future?
    printf "============ mkdir for uploads - or copy a zip file later\n"
    mkdir -p /var/www/$DOMAIN/uploads
    # ln -s the release - if /var/www/$DOMAIN/current exists, ln -s /var/www/$DOMAIN/uploads /var/www/$DOMAIN/current/html/wp-content/uploads
    if [ -d "/var/www/$DOMAIN/current" ]; then
        printf "============ /var/www/$DOMAIN/current exists, ln -s /var/www/$DOMAIN/uploads /var/www/$DOMAIN/current/html/wp-content/uploads\n"
        ln -s /var/www/$DOMAIN/uploads /var/www/$DOMAIN/current/html/wp-content/uploads
    fi
fi

# adjust permissions and ownership on /var/www/$DOMAIN
printf "============ Adjust permissions and ownership on /var/www/$DOMAIN\n"
chmod -R 775 /var/www/$DOMAIN
chown -R $OWNER_USER:$DAEMON_USER /var/www/$DOMAIN

# print that we are done
# if /var/www/simple-docker exists, then print message about "SimpleDocker Site Example is at http://localhost:3090"
if [ -d "/var/www/simple-docker" ]; then
    printf "============ ✅ Setup-Site Script Done - SimpleDocker Site Example is at http://localhost:3090/\n\n"
else
    printf "============ ✅ Setup-Site Script Done.\n\n"
fi
