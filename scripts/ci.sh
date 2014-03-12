#!/bin/bash

set -e

# make sure /var/www/bixby/current is always mounted
sudo mount -a

set +x
source $HOME/.bash_profile
rvm use default

# set here to avoid rvm spam
unset cd
set -x

# delete old screenshots
find /tmp -type f -name 'screenshot-*' -ctime +7 -delete

cd /opt/bixby-integration

scripts/manager/stop.sh
scripts/agent/stop.sh

scripts/manager/upgrade.sh
scripts/agent/upgrade.sh

cd tests
bundle install
bundle exec micron
