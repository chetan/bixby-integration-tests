#!/usr/bin/env bash

# install bixby-manager

source $HOME/.rvm/scripts/rvm

export RAILS_ENV=staging
b=/var/www/bixby
s=$b/shared
c=$b/current
sudo mkdir -p $s/log $s/bixby $s/pids $c
sudo chown -R vagrant:vagrant $b

if [ -d $c/.git ]; then
  # alreeady checked out, just pull
  cd $c
  git pull
else
  # clone
  git clone /opt/bixby-integration/src/manager $c
  cd $c
  cp -a /opt/bixby-integration/src/manager/.bundle .
fi

mkdir -p tmp
cd tmp
ln -sf $s/pids .
cd ..
ln -sf $s/log .

cp -a /opt/bixby-integration/src/manager/vendor/cache vendor/cache
bundle install --local
cd config
cp -a /opt/bixby-integration/manager/database.yml .
cp -a /opt/bixby-integration/manager/bixby.yml .
cp -a /opt/bixby-integration/manager/mongoid.yml .
cd ..
mkdir -p log

cd $c
rake db:setup bixby:update_repos

# assets not compiling for some reason
# assets:clobber assets:precompile

# start services
sudo RAILS_ENV=staging god -c $c/config/deploy/bixby.god
