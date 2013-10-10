#!/usr/bin/env bash

# stop manager and delete all data

sudo RAILS_ENV=staging god terminate
cd /var/www/bixby/current
rake db:drop
redis-cli flushall
rm -rf /var/www/bixby/

# reinstall
/opt/bixby-integration/scripts/install_manager.sh
