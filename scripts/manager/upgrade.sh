#!/usr/bin/env bash

# install bixby-manager

set +x
source $HOME/.rvm/scripts/rvm
export RAILS_ENV=integration
unset cd
set -x

bixby=/var/www/bixby
shared=$bixby/shared
current=$bixby/current

# cleanup existing data
sudo rm -rf $bixby/shared
sudo mkdir -p $shared/log $shared/bixby $shared/pids
sudo chown -R vagrant:vagrant $bixby/shared/

echo "updating manager"
cd $current
git pull
bundle install --local > /dev/null

# copy configs
cp -a /opt/bixby-integration/manager/database.yml \
      /opt/bixby-integration/manager/bixby.yml \
      /opt/bixby-integration/manager/mongoid.yml \
      $current/config/

cd $current
rake db:drop >/dev/null
rake db:create db:schema:load >/dev/null
RAILS_ENV=integration RAILS_GROUPS=assets rake \
  db:seed bixby:update_repos assets:precompile >/dev/null
