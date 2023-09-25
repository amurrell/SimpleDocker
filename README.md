# SimpleDocker

A **Simple Docker** container with only Ubuntu. Nothing else installed, just clean server - _a true blank canvas_.

Use for **local development of provisioning scripts** (eg. bash scripts) to setup cloud servers - whether starting from scratch, testing upgrades, or testing version compatibility.

... ✋ But wait!  There's more! We added docker/version customizations, an optional script-provisioning boilerplate to help generate them from scratch, and pre-run scripts to avoid repetition and speed up local development.  Read the [highlights](#repo-highlights)!

---

## Contents

- [Overview](#overview) | [Repo Highlights](#repo-highlights)
- [Install & Use](#install--use)
- [Pre-Runs](#configure-pre-run-scripts) | [Changing Pre-Runs & Docker Re-Caching](#changing-the-pre-run-script)
- [Writing Scripts](#scripts) | [Running Scripts](#running-scripts) | [Compiling Scripts](#compiling-scripts)
- [Configure Dockerfile & docker-compose.yml](#configure-dockerfile-or-docker-compose)
- [Webserver & Local Development w/ one](#webserver--local-development-with-a-webserver)


---

## Overview

With a local development environment for cloud provisioning scripts, you can more efficiently repeat test runs. Easy to erase the machine and restart it as a clean server via shell scripts: `./docker-up`, `./docker-ssh`, `./docker-down`.

🎉 Additionally, Simple Docker offers **Pre-Run** scripts, which help you put certain portions of your scripts - that are redundant, do not need testing, or take a while to install - into the Docker build process to leverage docker caching. This means docker-down & up can take you to a "blank" **boilerplate** canvas instead! 🎨

- If you don't have stack script yet, the example pre-run in this repo installs [LEMP-setup-guide](https://github.com/amurrell/LEMP-setup-guide) (PHP, Nginx, Mysql/MariaDB) which you can also use on production servers so this serves as a great place to start a pre-run script from! If you need specific versions, you can actually customize the LEMP-setup-guide quite a bit with override versioning to your needs!

- Additionally, if you have literally no provisioning scripts yet and need to start them, you can use `./docker-script -t simple <server-name>` to generate a boilerplate and examples for you to start with. When done, you can compile the pre-run and your server scripts to use on your cloud servers `./docker-script -c -n <server-name>`.

### Repo Highlights:

- Use any version of Ubuntu (tested minimum: 16.04)
- Can completely start over and get a blank canvas on each run.
- Simple commands: `./docker-up`, `./docker-down`, `./docker-ssh`
- Create a ["pre-run script" to leverage **docker caching**](#configure-pre-run-scripts) on redundant setup & installations in order to target parts of your scripts that need testing via multiple runs!
- Example pre-run script using [LEMP-setup-guide](https://github.com/amurrell/LEMP-setup-guide) included, and you can use it on your cloud server too. Serves as an excellent boilerplate for laravel, wordpress or vueJS/react projects too! Has additional installations in that project for composer, nvm, pm2 etc. You can change versions of things it installs very easily.
- For even more customization, [edit the `Dockerfile-computed`](#Configure-Dockerfile) to your liking - eg. edit default packages the server may have on it to mirror your cloud setup.
- Logging by default - Pre-run scripts AND your own scripts will out to file and stdoutput so you can see how your scripts ran and where they failed. For pre-runs, simply `./docker-log` while your machine is on. For your own scripts, make sure they output where you want - eg. `scripts/server-<server-name>.log`
- Don't have any provisioning scripts yet? We added `./docker-script -t <template> -n <server-name>` to help you get started with a whole folder of setup scripts to execute in order.
- Ready for production? When you're satisfied with your test runs, you can compile your active pre-run and server script into one script via command `./docker-script -c -n <server-name>`. Simply copy the `scripts/server-<server-name>` to your server and run the compiled version via `./compile-<server-name>`.
- Don't want to copy folders to your server? Want to version control your provisioning scripts? Sure! Use the devops template instead `./docker-script -t devops -n <server-name` to pull the scripts from a devops repository.

[↑ Contents](#contents)

---

## Install & Use

- clone

        git clone git@github.com:amurrell/SimpleDocker.git
        cd SimpleDocker

- optional: change ubuntu version, or keep default 20.04

        echo "22.04" > override-ubuntu-version

- to build and start up your container:

        ./docker-up

- to view log output of a pre-run script

        ./docker-log

- to ssh into your container:

        ./docker-ssh

- trigger scripts/script-* inside container via volume

        cd /var/www/simple-docker/scripts/
        ./script-my-server-setup

- to shutdown your container & clear everything:

        ./docker-down


[↑ Contents](#contents)

---

## Configure Pre-Run Scripts

Pre-run scripts are in the `pre-run/` folder - where there is initially a default script, an example, and a wrapper.

- `pre-run`

    The active pre-run script will always be at `pre-run/pre-run` and if it does not exist yet, the `pre-run-default` file will be copied to it on `./docker-up`

- `pre-run-default`

    Does nothing but echo out how to use it if you want to.

- `pre-run-example`

    Can be copied to pre-run. It uses repo [LEMP-setup-guide](https://github.com/amurrell/LEMP-setup-guide) as an example. That project makes LEMP setup super easy and customizable (versioning) with Mysql/MariaDb, PHP, Nginx, and more - perfect for "pre run" setup!

    ```
    👉 cp pre-run/pre-run-example pre-run/pre-run && ./docker-up -d=true
    ```

- `pre-run-wrapper`

    This script calls the pre-run. It is used as the last step of the Dockerfile, thus enabling the pre-run functionality to be cached by docker. This would be ideal if it is static and not changing per run. Makes it faster to test WIP scripts via docker-ssh since the docker-up/down process will be cached.


[↑ Contents](#contents)


### Changing the pre-run script:

On first run of `./docker-up` it will copy `pre-run/pre-run-default` into `pre-run/pre-run` if one does not exist yet.

Changing the pre-run script is made easier with `./docker-set -p <suffix-name>` and will even prompt to backup your current pre-run just in case you have one already unsaved.

Run in the terminal:

```
# change pre-run/pre-run to pre-run-example
./docker-set -p example

# change pre-run/pre-run to pre-run-default
./docker-set -p default
```

Each time you change your pre-run script, you may need to force the docker container to re-cache when doing `./docker-up`

- optionally pass `./docker-up -c=true` for docker build option `no-cache`
- optionally pass `./docker-up -d=true` for same ^ plus verboseness

[↑ Contents](#contents)

---

## Scripts

- **Importing from elsewhere:**

    If you already have scripts that setup your server, use them by copying the contents into a file and name it `script-my_server`.
    Make it executable.
    Ensure that you are logging the output to a file of your choice - eg. `scripts/script-log-my_server.log`. You can reference the script-example to see how we log to both file and output.

    Read more in the running scipts section.

    ---

- **Starting from scratch? Want a boilerplate?**

    If you do not already have scripts or a concept of setup scripts for your stuff yet, then you can use `./docker-script -n <server-name>` along with `scripts/template/template-main` to generate a boilerplate for you to start with.

    You can make your own templates too! Just copy the template-main and edit them to your liking. The variables defined in this file will be dynamically read and prompted for by the `docker-script` command.

    ```
    ./docker-script -t <template> -n <server-name>
    ```

    This will create a new folder `scripts/script-<your-servername>` with init scripts based on the template-main and other templates scripts we prrovide. You can edit these as needed.

    ---

    A few concepts happen in this example file...

    - **Identity & SSH**

        The top of the script has a bunch of variables, some of which are secretative like SSH key pairs. If your cloud server lets your initalize servers with some secrets, you can move them there when in production and know they are available (eg. linode stack scripts). This initial identity can help you clone your original private repo with the things it may need from your vc remotes or privileged placed.

        - it also has a concept of `git@<repo-name>.github.com:<company>/<repo-name>.git` which allows us to define in the ssh configuration identity keys per domain so each server can have its own key, but the ssh configuration will only use the correct server key with correct domain (helps when it tries a bunch of keys that are wrong and you get locked out.)

    ---

    - **Devops Repository**

        In this example file - we are using a "devops" repository to house the setup scripts per server. You can make sure that those scripts do not store environment variables and will connect to AWS secrets manager or some other way of handling - but we are in no way encouraging any env vars stored in repos. However, the scripts themselves may be useful to have in a repository.

    ---

    - **LEMP-setup-guide**

        This repo has a concept of "custom scripts" that you can copy your own scripts into this folder with numerical prefixes and it will loop through and run them. Eg. your install scripts could be broken up like this:

        - 010-init-setup.sh
        - 020-php-config.sh
        - 030-nginx-config.sh
        - 040-pm2.sh
        - 050-redis.sh

    ---

    - **RAOU**

        This means that if you end your install script with -RAOU it will **R**un **A**s **O**wner **U**ser and the script will run as the OWNER_USER defined in the vars of the script. Useful if you need to install parts of your script with www-data (eg. composer, nvm, npm etc) and the rest of the setup need to happen with root (nginx servers, php listeners and confg, etc with sudo-needs).

        - 010-init-setup.sh
        - 020-php-config.sh
        - 025-composer-RAOU.sh
        - 030-nginx-config.sh
        - 035-web-app-RAOU.sh
        - 040-pm2-RAOU.sh
        - 050-redis.sh


[↑ Contents](#contents)

---

## Running Scripts

To run your scripts, first make sure you start the docker container:

`./docker-up`

Next, make sure you have put your script into the `scripts` folder with prefix `script` (to avoid version control issues we ignore every file in here that starts with script- and we allow script-example).

```
- scripts/
    - script-my_server_dev
    - script-my_server_prod
```

Each script should log the output to corresponding log file in your scripts folder (or wherever you want really) eg. `script-my_server_dev.log` or `script-log-my_server_dev.log` to avoid the naming completion being too similar to the script itself.


```
./docker-run -n my_server_dev
```

[↑ Contents](#contents)

---

## Compiling Scripts

When you are done testing your scripts, you can compile both the server scripts with the pre-run into one script to run on your cloud server.

```
./docker-compile -n my_server_dev -p pre-run-example -r
```

The `-r` flag is optional and means removing emojis from the script. _(linode stack scripts do not like emojis)_.
The `-p` flag is optional and will default to `pre-run` if not passed.

You will still need the entire `server-<server-name>` folder on your server, which will contain the compiled script. On the cloud, you will then run the compiled script.

```
./compiled-my_server_dev
```

[↑ Contents](#contents)

---

## Configure Dockerfile or Docker-compose

The first time you run `./docker-up` it will generate files `docker-compose-computed.yml` and `Dockerfile-computed`. Once these exist it will not touch them (except the docker-up will change ubuntu version in Dockerfile-computed looking for pattern xx.xx in Dockerfile-computed to replace). This means you can safely edit this files to your liking.

The computed files are not version controlled.

[↑ Contents](#contents)

---

## Webserver & Local Development with a Webserver

This simple docker does not have a webserver, but if you were to install & configure one to run on the container's port 80, you'd see your site here: http://localhost:3090 (defined in docker-compose.yml). You will need to make sure your webserver is configured (eg. nginx is listening on port 80 and there's a root foldfer and files. Once making edits, you may need to restart your webserver)

- Looking for a Server Stack Starter (eg. LEMP)?

    Not sure what to put in your pre-run or how to get started? Try using [LEMP-Setup-Guide]((https://github.com/amurrell/LEMP-setup-guide)

    If you use this (pre-run-example), then when you `./docker-ssh` you can go into `/var/www/LEMP-setup-guide/scripts` and use `./setup-site`. Answering the prompts, you can have it install a site based on a git clone (or skip) and it will prompt for nginx and php config files, and even setup a mysql db for you. The only real changes to make to get it working after this are:

    1. Edit `/etc/nginx/sites-enabled/yoursite` to remove the first block about listening on port 80 since it will redirect.

    2. test nginx - `nginx -t` and then restart nginx `sudo service nginx restart` if it passed.

    3. reloads php - `sudo service php8.0-fpm reload` or start if it was not running already. or use different version of php. (in your pre-run script you can override LEMP versions before you actually execute it so that you get the versions of things you want.)

    Be warned that this will all die after `./docker-down` (minus the pre-run of course)... This is actually really nice to test out your stuff... getting a clean slate each time.

    👉 Also, if you enjoyed this setup-site script, realize that this LEMP setup guide is pretty cool on a REAL cloud server because you can setup sites very quickly and add things like: log-rotation, cerbot (lets encrypt) ssl certificates, nvm, pm2, compsoer etc from this same project!

    👀 If you are looking for local devlopement solution for a webserver based project to work on the web application itself, we have that for you too! 👇

- Looking for a Local Development Environment with a webserver?

    Typically you would not install a webserver after creating a Docker container - it would be done in the Dockerfile so it can be cached and your databases would persist.

    You can configure the Dockerfile yourself how you like... or you can just use [DockerLocal](https://github.com/amurrell/DockerLocal) which has nginx, php7, composer, mysql/mariadb, memcached/redis - with similar versioning built in

[↑ Contents](#contents)
