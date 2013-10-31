#!/usr/bin/env bash

# make sure it's stopped first
/opt/bixby-integration/scripts/manager/stop.sh

# install bixby-manager

source $HOME/.rvm/scripts/rvm
export RAILS_ENV=staging

bixby=/var/www/bixby
shared=$bixby/shared
current=$bixby/current

# cleanup existing data
sudo rm -rf $bixby/shared

echo "creating $bixby"
sudo mkdir -p $shared/log $shared/bixby $shared/pids $current
sudo chown -R vagrant:vagrant $bixby/shared/

echo "updating manager"
if [ ! -d $current/.git ]; then
  # mount src dir to current
  sudo umount -f $current
  sudo mount --bind /opt/bixby-integration/src/manager $current

  # link in shared dirs
  cd $current
  mkdir -p tmp
  ln -sf $shared/pids $current/tmp/
  ln -sf $shared/log $current/
fi

# bundle install
bundle install --local > /dev/null

# copy configs
cp -a /opt/bixby-integration/manager/database.yml \
      /opt/bixby-integration/manager/bixby.yml \
      /opt/bixby-integration/manager/mongoid.yml \
      $current/config/

cd $current
rake db:drop >/dev/null
rake db:create db:schema:load >/dev/null
RAILS_ENV=staging RAILS_GROUPS=assets rake \
  db:seed bixby:update_repos assets:precompile > /dev/null
