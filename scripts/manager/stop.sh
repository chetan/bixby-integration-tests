#!/usr/bin/env bash

# stop manager, cleanup databases
sudo RAILS_ENV=integration god terminate
sudo pkill -9 -u 0 -U 0 -f god
pkill -9 -f sidekiq
pkill -9 -f puma
cd /var/www/bixby/current
bundle install --local > /dev/null
rake db:drop
redis-cli flushall > /dev/null

# reset mongodb data dir
sudo service mongodb stop
sudo rm -rf /var/lib/mongodb
sudo mkdir /var/lib/mongodb
sudo chown mongodb:mongodb /var/lib/mongodb
sudo service mongodb start

rm -rf /var/www/bixby/shared/bixby/*
