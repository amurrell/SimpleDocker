# SimpleDocker
Docker - Ubuntu 20.04LTS w/ easy shell commands: docker-up, docker-down, docker-ssh

There is no webserver. This is just pure Ubuntu 20.04LTS pretty much. Could be a good starting point for modifying the Dockerfile to your needs.

## Clone, up, ssh, down

```
git clone git@github.com:amurrell/SimpleDocker.git
cd SimpleDocker
# to build and start up your container:
./docker-up
# to ssh into your container:
./docker-ssh
# to shutdown your container:
./docker-down
```

---

### No Webserver

This simple docker does not have a webserver, but if you were to install & configure one to run on the container's port 80, you'd see your site here: http://localhost:3090

### Try DockerLocal if you want one

Typically you would not install a webserver after creating a Docker container - it would be done in the Dockerfile. You can configure the Dockerfile yourself how you like... or you can just use [DockerLocal](https://github.com/amurrell/DockerLocal) which has nginx, php7, composer, mysql, memcached.