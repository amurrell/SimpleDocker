#!/usr/bin/env bash

printf "============ Script: Deploy Config w/ deploy-commands repo\n"

# set deploy_user to the current user - if you want to hard code this, change the file to your liking.
DEPLOY_USER=$(whoami)

echo "---------------------------------- INFO -----------------------------------"
echo ""
echo "This init script will setup deploy.sh and deploy.config.json into your deployment user's home folder."
echo ""
echo "The deploy.sh script facilitates deployment via GitHub Actions combined with sites setup with git repo amurrell/deploy-commands"
echo ""
echo "Prerequisites:"
echo "  - Ensure that 'deploy-comands/deploy-workflow.yaml' has been copied and commited into each site repo."
echo "  - The file should be copied to the site's workflow directory at:"
echo "    '.github/workflows/'"
echo "  - Ensure the github repository has secrets in place that the workflow file needs"
echo "  - That the server has an authorized_key installed to allow the workflow to connect to this server"
echo ""
echo "For more details, refer to the documentation at [https://github.com/amurrell/deploy-commands#automated-deployments-via-github-workflow]."
echo ""
echo "PS. you can run this script multiple times to regenerate the deploy.config.json if you add more sites or need to recompute."
echo "---------------------------------------------------------------------------"

# use curl to get the deploy-commands deploy.sh script
curl -o /home/$DEPLOY_USER/deploy.sh https://raw.githubusercontent.com/amurrell/deploy-commands/main/deploy.sh
# ensure it is executeable
chmod +x /home/$DEPLOY_USER/deploy.sh

# source .bashrc for node
printf "============ Source bash profile again to ensure node access\n"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
source ~/.bashrc

# Make a config file for the deploy script to use, based on what's on this server.
# If a deploy.config.json exists at /home/$DEPLOY_USER/deploy.config.json, then prompt to overwrite it (eg. someone runs this to update for more sites)

if [ -f "/home/$DEPLOY_USER/deploy.config.json" ]; then
    printf "============ /home/$DEPLOY_USER/deploy.config.json exists, overwrite it? (y/n)\n"
    read -r OVERWRITE
    if [ "$OVERWRITE" = "y" ]; then
        printf "============ Overwriting /home/$DEPLOY_USER/deploy.config.json\n"
        rm /home/$DEPLOY_USER/deploy.config.json
    else
        printf "============ Not overwriting /home/$DEPLOY_USER/deploy.config.json\n"
        exit 1
    fi
fi

# Generate config file
# We want to loop through each /var/www/<domain> site and look for a deploy-commands repo - only work with sites that have one eg. /var/www/<domain>/deploy-commands
# - if there is no subdomain in the domain, make an entry for "prod"
# - if there is a subdomain, make an entry for the subdomain - eg. "dev.site.com" -> "dev", "staging.site.com" -> "staging"
# then for each, want to get the path to the releases folder, and the path to the commands folder, and the github repo in the format <user>/<repo-name>
# and save them into a deploy.config.json file
# with the format:
# {
#   "user/repo": {
#     "prod": {
#       "releases": "/var/www/<domain>/releases",
#       "commands": "/var/www/<domain>/commands"
#     },
#     "dev": {
#       "releases": "/var/www/<dev.domain>/releases",
#       "commands": "/var/www/<dev.domain>/commands"
#     }
# }

config_file="deploy.config.json"

# Start with an empty object
echo "{}" > $config_file

# Loop through each directory in /var/www/
for domain_path in /var/www/*/; do
    # Extract the domain from the path
    domain=$(basename $domain_path)

    # trim domain_path to remove trailing slash
    domain_path=${domain_path%/}

    # Check if deploy-commands directory exists
    if [[ -d "$domain_path/deploy-commands" ]]; then
        # Determine the environment: prod, dev, staging, etc.
        # if domain starts with www or has no subdomain - www.site.com or site.com, then prod
        if [[ $domain =~ ^www\. ]] || ! [[ $domain =~ \..*\. ]]; then
            env="prod"
        else
            IFS='.' read -ra ADDR <<< "$domain"
            env="${ADDR[0]}"
        fi

        # Extract the GitHub user/repo using git
        pushd "$domain_path/current" > /dev/null
        git_url=$(git config --get remote.origin.url)
        repo=$(echo $git_url | sed -E 's/.*:([^\:\/]*)\/([^\:\/]*)\.git$/\1\/\2/')
        popd > /dev/null

        # ensure the site has a commands folder
        COMMANDS="$domain_path/commands"
        if [ ! -d "$COMMANDS" ]; then
            printf "============ $COMMANDS does not exist, skip this entry\n"
            continue
        fi
        # ensure the site has a releases folder
        RELEASES="$domain_path/releases"
        if [ ! -d "$RELEASES" ]; then
            printf "============ $RELEASES does not exist, skip this entry\n"
            continue
        fi

        # Use Node.js to append to the JSON file
        node -e "
        const fs = require('fs');
        const configPath = '$config_file';
        const data = fs.readFileSync(configPath, 'utf8');
        const json = JSON.parse(data);
        const repo = '$repo';  // Interpolate the bash variable as a JS string
        const env = '$env';    // Interpolate the bash variable as a JS string
        json[repo] = json[repo] || {};
        json[repo][env] = {
            releases: '$domain_path/releases',
            commands: '$domain_path/commands'
        };
        fs.writeFileSync(configPath, JSON.stringify(json, null, 2));
        "
    fi
done

# cat the config file
printf "============ deploy.config.json has been generated. See below:\n"
cat $config_file

# Copy the file to the deploy user's home directory
# if not the same file, then cp it
if [ ! -f "/home/$DEPLOY_USER/$config_file" ] || ! cmp -s $config_file /home/$DEPLOY_USER/$config_file; then
    printf "============ Copying $config_file to /home/$DEPLOY_USER/$config_file\n"
    cp $config_file /home/$DEPLOY_USER/$config_file

    # if /var/www/simple-docker does not exist, then remove the config_file
    if [ ! -d "/var/www/simple-docker" ]; then
        rm $config_file
    fi
fi
