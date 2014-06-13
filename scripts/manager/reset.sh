#!/usr/bin/env bash

# setup manager data
cd /var/www/bixby/current
rm -f log/*
bundle exec rake db:create db:schema:load > /dev/null
bundle exec rake db:seed bixby:update_repos > /dev/null
