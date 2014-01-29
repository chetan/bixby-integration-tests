#!/bin/bash

set -e

set +x
source $HOME/.bash_profile
rvm use default

# set here to avoid rvm spam
unset cd
set -x

cd /opt/bixby-integration

scripts/manager/stop.sh
scripts/agent/stop.sh

scripts/manager/upgrade.sh
scripts/agent/upgrade.sh

cd tests
bundle install
bundle exec micron
