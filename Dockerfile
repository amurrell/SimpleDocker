# Set the base image to ubuntu:16.04
FROM        ubuntu:20.04

# File Author / Maintainer
LABEL maintainer="Angela Murrell <me@angelamurrell.com>"

# Update the repository and install nginx and php7.4
ENV DEBIAN_FRONTEND=noninteractive

# Update the repository and install nginx and php7.0
RUN apt-get update && \
  apt-get install -y nano && \
  apt-get install -y curl && \
  apt-get install -y sudo && \
  apt-get install -y wget && \
  apt-get install -y git && \
  apt-get install -y unzip && \
  apt-get install -y ruby-full && \
  apt-get install -y ufw && \
  apt-get install -y apt-utils && \
  apt-get install -y software-properties-common && \
  apt-get install -y apt-transport-https && \
  apt-get install -y openssh-client && \
  apt-get -y --no-install-recommends install apt-utils && \
	apt-get -y install freetds-bin tdsodbc unixodbc unixodbc-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Install more stuff
RUN	apt-get update && \
  apt-get -y install libcurl3-openssl-dev && \
  apt-get -y install libyaml-dev

# export var for nano to work in command line
ENV TERM xterm

# Set workdir
WORKDIR /var/www/

# SSH
RUN mkdir /root/.ssh

# Add site directory
RUN mkdir /var/www/simple-docker

# Append source brc alias to the bashrc profile file
RUN echo 'alias brc="source /root/.bashrc"' >> /root/.bashrc

# Adjust www-data
RUN usermod -u 1000 www-data

CMD sleep infinity
