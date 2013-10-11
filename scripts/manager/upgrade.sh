#!/usr/bin/env bash

# make sure it's stopped first
/opt/bixby-integration/scripts/manager/stop.sh

# install bixby-manager

source $HOME/.rvm/scripts/rvm
export RAILS_ENV=staging

bixby=/var/www/bixby
shared=$bixby/shared
current=$bixby/current

sudo rm -rf /var/www/bixby

echo "creating $bixby"
sudo mkdir -p $shared/log $shared/bixby $shared/pids $current
sudo chown -R vagrant:vagrant $bixby

echo "updating manager"
if [ -d $current/.git ]; then
  # alreeady checked out, just pull
  cd $current
  git reset --hard
  git pull
else
  # clone
  git clone /opt/bixby-integration/src/manager $current
  cd $current
  cp -a /opt/bixby-integration/src/manager/.bundle .
fi

mkdir -p tmp
ln -sf $shared/pids $current/tmp/
ln -sf $shared/log $current/

cp -a /opt/bixby-integration/src/manager/vendor/cache vendor/cache
bundle install --local
cp -a /opt/bixby-integration/manager/database.yml \
      /opt/bixby-integration/manager/bixby.yml \
      /opt/bixby-integration/manager/mongoid.yml \
      $current/config/

cd $current
rake db:drop
rake db:reset bixby:update_repos > /dev/null
RAILS_ENV=staging RAILS_GROUPS=assets rake assets:clobber assets:precompile
