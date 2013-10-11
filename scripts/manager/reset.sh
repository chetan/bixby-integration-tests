#!/usr/bin/env bash

# stop manager, cleanup databases
sudo RAILS_ENV=staging god terminate
sudo pkill -9 -u 0 -U 0 -f sidekiq
sudo pkill -9 -u 0 -U 0 -f puma
[ -f /var/www/bixby/current/Rakefile ] && cd /var/www/bixby/current && rake db:drop
redis-cli flushall > /dev/null
rm -rf /var/www/bixby/shared/bixby/*

# setup manager data
cd /var/www/bixby/current
rake db:create db:schema:load > /dev/null
rake db:seed bixby:update_repos > /dev/null
