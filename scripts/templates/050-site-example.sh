#!/usr/bin/env bash

# Install Server Specific

###############################

printf "============ Script: Site Example\n"

# Install Server Specific

###############################

OWNER_USER='ubuntu'
DAEMON_USER='www-data'
SCRIPT_USER='root'
DOMAIN='example.com'
GITHUB_REPO='https://github.com:amurrell/developer-wordpress.git'
PHP_VERSION=$(cat /var/www/LEMP-setup-guide/config/versions/php-version)
# use for location of keys on prod!
BASE_PATH_DEPLOY_KEYS=/root/devops/config/deployment-keys
# if override-php-version is set, use that
if [ -f "/var/www/LEMP-setup-guide/config/versions/override-php-version" ]; then
    PHP_VERSION=$(cat /var/www/LEMP-setup-guide/config/versions/override-php-version)
fi

# if using simple-docker, deploy keys are found at /var/www/simple-docker/scripts/server-$DOMAIN/
# if running via devops repo, deploy keys are found at $BASE_PATH_DEPLOY_KEYS/
if [ -f "/var/www/simple-docker/scripts/server-$DOMAIN/$DOMAIN-deploy_key.pub" ]; then
    DEPLOY_KEY_PUBLIC_FILE=/var/www/simple-docker/scripts/server-$DOMAIN/$DOMAIN-deploy_key.pub
else
    DEPLOY_KEY_PUBLIC_FILE=$BASE_PATH_DEPLOY_KEYS/$DOMAIN-deploy_key.pub
fi

if [ -f "/var/www/simple-docker/scripts/server-$DOMAIN/$DOMAIN-deploy_key" ]; then
    DEPLOY_KEY_PRIVATE_FILE=/var/www/simple-docker/scripts/server-$DOMAIN/$DOMAIN-deploy_key
else
    DEPLOY_KEY_PRIVATE_FILE=$BASE_PATH_DEPLOY_KEYS/$DOMAIN-deploy_key
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
sudo service php8.2-fpm start &


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
# 1st time you run, set these to null and answer prompts to generate keys
# - add to github, and store contents (from logs) into files in this servers' scripts folder.
#   --deploy-key-public-file=null \
#   --deploy-key-private-file=null \
# and when you have keys:
#   --deploy-key-public-file=$DEPLOY_KEY_PUBLIC_FILE \
#   --deploy-key-private-file=$DEPLOY_KEY_PRIVATE_FILE \
# or use public repo with https: to avoid needing keys or being prompted for ssh password

# with simple docker testing - use these values
# --nginx-site-conf-path=/var/www/simple-docker/scripts/templates/site.nginx.conf \
# --php-site-conf-path=/var/www/simple-docker/scripts/templates/site.php-fpm.conf \
# but leave these out to use defaults if on production server

./setup-site \
  --domain=$DOMAIN \
  --owner-user=$OWNER_USER \
  --github=$GITHUB_REPO \
  --deploy-key-public-file=null \
    --deploy-key-private-file=null \
  --php-pools=true \
  --nginx-with-php=true \
  --nginx-site-conf-path=/var/www/simple-docker/scripts/templates/site.nginx.conf \
  --php-with-mysql=true \
  --php-site-conf-path=/var/www/simple-docker/scripts/templates/site.php-fpm.conf \
  --mysql-create-db=true \
  --mysql-root-user=root \
  --mysql-root-pass=password \
  --database-name=site_com \
  --database-user=site.com \
  --database-pass=cRaZyPaSs \
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

# adjust permissions and ownership on /var/www/$DOMAIN
printf "============ Adjust permissions and ownership on /var/www/$DOMAIN\n"
chmod -R 775 /var/www/$DOMAIN
chown -R $OWNER_USER:$DAEMON_USER /var/www/$DOMAIN


# print that we are done
printf "============ ✅ Setup-Site Script Done - Site Example on simple-docker is at http://localhost:3090/\n\n"

# note that if testing in simple-docker and there are multiple sites, may need to use ProxyLocal with local site.yml configuration
# that's not tested yet.
