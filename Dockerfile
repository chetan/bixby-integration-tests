
# Bixby Integration container

FROM ubuntu:precise
MAINTAINER Chetan Sarva <csarva@pixelcop.net>

ENV DEBIAN_FRONTEND noninteractive
ENV http_proxy http://192.168.80.98:8000
ENV https_proxy http://192.168.80.98:8001

USER root

# Setup basic env

RUN echo '127.0.0.1 localhost.localdomain localhost' >> /etc/hosts
RUN useradd -d /home/bixby -m -s /bin/bash bixby

# use proxy for APT
RUN echo "Acquire { Retries \"0\"; HTTP { Proxy \"$http_proxy\"; }; };" > /etc/apt/apt.conf.d/30apt-proxy

# # INSTALL DEPS
RUN apt-get -qq update
RUN apt-get -qq -y install python-software-properties sudo curl wget

# workaround, instead of add, wget!
# ADD etc/precise-sources.list /etc/apt/sources.list
# Because ADD command breaks the cache of everything which follows
RUN curl -skL https://raw.github.com/chetan/bixby-integration-tests/master/etc/precise-sources.list > /etc/apt/sources.list

RUN https_proxy="" add-apt-repository -y ppa:nginx/stable
RUN https_proxy="" add-apt-repository -y ppa:chris-lea/redis-server
RUN https_proxy="" apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
RUN echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' > /etc/apt/sources.list.d/10gen.list

RUN apt-get -qq update
RUN apt-get -qq -y install git ruby rubygems libcurl4-openssl-dev libmemcache-dev libsasl2-dev libmysqlclient-dev build-essential libpq-dev postgresql-9.1 postgresql-client-common most htop vim-nox gawk libyaml-dev libsqlite3-dev sqlite3 autoconf libgdbm-dev libreadline6-dev libncurses5-dev automake libtool bison libffi-dev screen mongodb-10gen redis-server nginx

# RUBY STUFF
RUN gem install god --no-ri --no-rdoc

# update sudoers before switching users
RUN echo 'bixby ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# setup psql
# NOTE: when services need to be running for another command to succeed
#       we MUST start that service in the same RUN line!
USER postgres
RUN service postgresql start ; echo CREATE USER bixby WITH SUPERUSER | psql
USER root
RUN echo "local   all             bixby                                peer" >> /etc/postgresql/9.1/main/pg_hba.conf

# checkout code
RUN cd /opt; https_proxy="" git clone https://github.com/chetan/bixby-integration-tests.git bixby-integration; chown -R bixby bixby-integration

# setup nginx
RUN cp /opt/bixby-integration/manager/nginx.conf /etc/nginx/sites-enabled/bixby
RUN rm -f /etc/nginx/sites-enabled/default



################################################################################
# Switch to user bixby now that we have it

USER bixby
ENV HOME /home/bixby

RUN cd; echo 'source $HOME/.bashrc' >> .bash_profile

# make sure curl/wget work with HTTPS intercept
RUN cd; echo insecure > .curlrc; echo check_certificate=off > .wgetrc

RUN curl -sL https://get.rvm.io | bash -s stable --ruby

# don't think we need this??
RUN cd; /bin/echo -e "#!/usr/bin/env bash\nsource /home/bixby/.bash_profile\n\$*" > with_env; chmod 755 with_env
# RUN cd /opt/bixby-integration/tests; ~/with_env bundle install


