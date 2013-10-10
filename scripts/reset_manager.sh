#!/usr/bin/env bash

# stop manager and delete all data

sudo RAILS_ENV=staging god terminate
[ -f /var/www/bixby/current/Rakefile ] && cd /var/www/bixby/current && rake db:drop
cd
redis-cli flushall
sudo rm -rf /var/www/bixby/

# reinstall
/opt/bixby-integration/scripts/install_manager.sh
