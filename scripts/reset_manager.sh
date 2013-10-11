#!/usr/bin/env bash

# stop manager and delete all data

sudo RAILS_ENV=staging god terminate
sudo pkill -9 -u 0 -U 0 -f sidekiq
sudo pkill -9 -u 0 -U 0 -f puma
[ -f /var/www/bixby/current/Rakefile ] && cd /var/www/bixby/current && rake db:drop
cd
redis-cli flushall
sudo rm -rf /var/www/bixby/

# reinstall
/opt/bixby-integration/scripts/install_manager.sh
