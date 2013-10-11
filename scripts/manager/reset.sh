#!/usr/bin/env bash

# setup manager data
cd /var/www/bixby/current
rake db:create db:schema:load > /dev/null
rake db:seed bixby:update_repos > /dev/null
