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

- Additionally, if you have literally no provisioning scripts yet and need to start them, you can use `./docker-script -n <server-name>` to generate a boilerplate and examples for you to start with. When done, you can compile the pre-run and your server scripts to use on your cloud servers `./docker-script -c -n <server-name>`.

### Repo Highlights:

- Use any version of Ubuntu (tested minimum: 16.04)
- Can completely start over and get a blank canvas on each run.
- Simple commands: `./docker-up`, `./docker-down`, `./docker-ssh`
- Create a ["pre-run script" to leverage **docker caching**](#configure-pre-run-scripts) on redundant setup & installations in order to target parts of your scripts that need testing via multiple runs!
- Example pre-run script using [LEMP-setup-guide](https://github.com/amurrell/LEMP-setup-guide) included, and you can use it on your cloud server too. Serves as an excellent boilerplate for laravel, wordpress or vueJS/react projects too! Has additional installations in that project for composer, nvm, pm2 etc. You can change versions of things it installs very easily.
- For even more customization, [edit the `Dockerfile-computed`](#Configure-Dockerfile) to your liking - eg. edit default packages the server may have on it to mirror your cloud setup.
- Logging by default - Pre-run scripts AND your own scripts will out to file and stdoutput so you can see how your scripts ran and where they failed. For pre-runs, simply `./docker-log` while your machine is on. For your own scripts, make sure they output where you want - eg. `scripts/server-<server-name>.log`
- Don't have any provisioning scripts yet? We added `./docker-script -t <template> -n <server-name>` to help you get started with a whole folder of setup scripts to execute in order. The `-t` flag is optional and will default to `main` if not passed. You can make your own templates too!
- Ready for production? When you're satisfied with your test runs, you can compile your active pre-run and server script into one script via command `./docker-script -c -n <server-name>`. Simply copy the `scripts/server-<server-name>` to your server and run the compiled version via `./compile-<server-name>`.
- Don't want to copy folders to your server? Want to version control your provisioning scripts? Sure! Set the `DEVOPS_REPO=true` to use scripts from another repository.

[↑ Contents](#contents)

---

## Install & Use

### Clone

    git clone git@github.com:amurrell/SimpleDocker.git
    cd SimpleDocker

### Optional: change ubuntu version, or keep default 20.04

    echo "22.04" > override-ubuntu-version

### Build & Run

    ./docker-up

After docker boots, you'll get these `POST-ACTION` options: 

```
1. Run a script     # ./docker-run -n <server-name>
2. SSH              # ./docker-ssh (into container)
3. View logs        # ./docker-log (output of pre-run only)
4. Create a script  # ./docker-script -n <server-name>
```

**Quick Tips & Info:**

<details>
<summary><strong>What is a pre-run script?</strong></summary>

A "pre-run" script in SimpleDocker is a script (in `pre-runs/pre-run`) that needs to run before your other provisioing scripts. It is useful for installing things that are redundant, take a long time to install, or you do not need to test. It is installed by the actual dockerfile - that way you can leverage docker caching and speed up your local development of provisioning scripts. 

This could be stuff like: installing nginx, php, mysql. You know you will need these things, but you don't need to test them every time you run your scripts. You can test your scripts by running them manually after the pre-run has installed the things you need.

</details>

<details>
<summary><strong>Test a script real quick?</strong></summary>

If you want to try something out quickly you could copy a script into the scripts folder and access it in the container (because of a shared volume) and run it manually.

```
./docker-ssh # into the container
cd /var/www/simple-docker/scripts/any-script.sh
chmod +x any-script.sh
./any-script.sh
```

</details>

<details>

<summary><strong>Create a Server "Script" (a folder of scripts intended to setup a server)</strong></summary>

This action will:
- create a folder `scripts/server-<server-name>`
- add a run script `run-<server-name>` (based on template `main`)
- prompt for variables definitions to populate the `run-<server-name>` script
- add a log file `script-log-<server-name>.log` to the folder
- add the boilerplate provisioning scripts to the folder, based on templates.
- ask if you want to run the scripts now.

</details>

<details>
<summary><strong>After generating, how to edit the run scripts?</strong></summary>

After it is generated, of course you can edit it more to your needs - however, it's strongly encouraged to keep the `run-*` file standard so that you can regenerate it again if needed. The main differences should be your actual provisioning scripts that you add or adjust within the folder, and the variables you defined in the run script.

If you start to have a lot of new variables to define that were not prompted for, or you need to make a lot of changes to the run-script itself, you can make your own template and use it with the `-t` flag.
</details>

<details>
  <summary><strong>What is a run script?</strong></summary>

  This run script is what is called to setup variables and trigger your other provisioning scripts accordingly. This main run script will be based on `templates/main` - which has defined variables that will be prompted for at script creation time. This variable system is dynamic meaning you can copy this template and make your own templates with custom variable prompts. Once your template is ready, you can create those custom run scripts with: `./docker-script -t <template> -n <server-name>`.
</details>

<details>
  <summary>
  <strong>How to decide a server name? Is there a strategy?</strong>
  </summary>

You probably know the name or single use case of your server, so that is generally a good naming pattern. 

Additionally, I like to add things like `dev_` or `prod_` to the server name to indicate if it is a development server or production server. This helps me keep track of what I'm working on and what is live.

Specifically for local development of provisioning scripts within SimpleDocker, I like to use a suffix with `-simple` to indicate that it is not going to use a devops repo (yet). 

I use this to test out scripts and then when I'm ready to use it on a cloud server, I'll copy everything to my devops repo, commit, and then create another script with the same name but without the `-simple` suffix - and in this one, I set `DEVOPS_REPO=true` and answer the conditional devops-repo prompts. This way I can test out scripts locally using my `-simple` version, and then commit them to my devops repo when I'm ready - and test _that_ version locally as well.
</details>

<details>
<summary><strong>Run a Server Script</strong></summary>

If you do want to run with generated scripts to see it work (which includes "site-example" running a PHP site on nginx), you will need to use `pre-run-example`. 

Do that via `./docker-set -p example` and then `./docker-up -d=true`. 

This will ensure that PHP, mariadb, LEMP-Setup-Guide, etc. are installed - which are needed to run the "site-example" wordpress site.

Also, update the variables in `pre-run` to match your variables in `main` (eg. `PHP_VERSION`, `NODE_VERSION`, etc).

</details>

<details>
<summary><strong>Workflow with Local Development</strong></summary>

After initial build and script creation, you can edit your scripts and quickly retrigger them:

**Example:** Running a script after a fresh start

```
./docker-down && ./docker-up
============ POST-ACTION:
1. Run a script
2. SSH
3. View logs
4. Create a script

Enter the number of the post action you want to perform (ctrl+d to exit): 1
============ SELECT SCRIPT:
1. server-my_server

Enter the number of the script you want to run: 1

============= 🏃‍♀️ Running script: server-my_server
============ 🖥️	Server name: my_server
============ 🏃	Running script: scripts/server-my_server/run-my_server
```
</details>

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
    👉 ./docker-set -p example
    👉 ./docker-up -d=true
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

    If you already have scripts that setup your server, use them by copying the contents into a folder and name it `server-my_server`.
    Make your scripts executable.
    Ensure that you are logging the output to a file of your choice - eg. `scripts/server-my_server/script-log-my_server.log`. You can reference the script-example to see how we log to both file and output.

    Read more in the running scipts section.

    ---

- **Starting from scratch? Want a boilerplate?**

    If you do not already have scripts or a concept of setup scripts for your stuff yet, then you can use `./docker-script -n <server-name>` along with `scripts/template/template-main` to generate a boilerplate for you to start with.

    You can make your own templates too! Just copy the template-main and edit them to your liking. The variables defined in this file will be dynamically read and prompted for by the `docker-script` command.

    ```
    ./docker-script -t <template> -n <server-name>
    ```

    This will create a new folder `scripts/server-<your-servername>` with init scripts based on the template-main and other templates scripts we provide. You can edit these as needed.

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

To run your scripts, simply use the main command and guided prompts.

`./docker-up`

The easiest thing to do is follow the guided prompts to create or run scripts, because it will ensure proper naming conventions and logging when creating them - and it will avoid having to type the name of your scripts through switches, and let you choose number choices from a list.

For doing things manually:

- Make sure you have put your server-scripts into the `scripts/server-<server-name>` folder - notice the prefix `server` (to avoid version control issues we ignore every folder in here that starts with `server-`).

    ```
    - scripts/
        - server-my_server_dev
        - server-my_server_prod
    ```
- Run your scripts directly (remembering to `./docker-down` and `./docker-up` again for fresh start):

    ```
    # Syntax: ./docker-run -n <server-name>

    👉 ./docker-run -n my_server_dev
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
