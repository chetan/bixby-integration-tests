#!/bin/bash

set -e
unset cd
set -x

# /home/travis/build/chetan/bixby-integration-tests
TEST_ROOT=$( readlink -f $(dirname $(readlink -f $0))/.. )

sudo add-apt-repository -y ppa:nginx/stable
sudo apt-get -qq update
sudo apt-get -qq install nginx ruby rubygems
sudo gem install god --quiet --no-ri --no-rdoc

# setup nginx
sudo rm -f /etc/nginx/sites-enabled/*
sudo cp $TEST_ROOT/manager/nginx/nginx.conf /etc/nginx/nginx.conf
sudo cp $TEST_ROOT/manager/nginx/bixby.conf /etc/nginx/sites-enabled/bixby.conf
sudo service nginx restart

mkdir -p $HOME/src
cd $HOME/src
for proj in common client agent manager; do
  git clone https://github.com/chetan/bixby-$proj.git $proj
done
git clone https://github.com/chetan/api_auth.git
cd api_auth
git checkout -qb bixby origin/bixby

# install test deps
cd $TEST_ROOT/tests
bundle install --retry=3 --deployment


################################################################################
# install agent
\curl -sL https://get.bixby.io | bash -s


################################################################################
# install manager

echo "export RAILS_ENV=integration" >> ~/.bashrc

bixby=/var/www/bixby
shared=$bixby/shared
current=$bixby/current

echo "creating $bixby"
sudo mkdir -p $bixby
sudo cp -a $HOME/src/manager $current
cd $current
mkdir -p tmp
ln -sf $shared/pids $current/tmp/
ln -sf $shared/log $current/
bundle install --retry=3 --deployment
