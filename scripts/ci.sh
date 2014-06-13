#!/bin/bash

set -e

# make sure /var/www/bixby/current is always mounted
sudo mount -a

set +x
if [[ $USER != "travis" ]]; then
  # rvm hack, won't get used on travis
  source $HOME/.bash_profile
  rvm use default
fi

# set here to avoid rvm spam
unset cd
set -x

# delete old screenshots
sudo find /tmp -type f -name 'screenshot-*' -ctime +7 -delete

# update source repos
for repo in manager agent client common api_auth; do
  cd $HOME/src/$repo
  echo "* updating $repo"
  git pull -q
done

export TEST_ROOT=$( readlink -f $(dirname $(readlink -f $0))/.. )
cd $TEST_ROOT

# stop running daemons
scripts/manager/stop.sh
scripts/agent/stop.sh

# upgrade manager and agent
scripts/manager/upgrade.sh
scripts/agent/upgrade.sh

# run tests
cd tests
bundle install --quiet
bundle exec micron

# workaround for weird bug where exit code gets overwritten and always returns 0 instead
ret=$(cat .micron/last_run)
exit $ret
