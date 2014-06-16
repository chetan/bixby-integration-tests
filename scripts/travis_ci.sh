#!/bin/bash

set -e
set +x
# set here to avoid rvm spam
unset cd
set -x

# # update source repos
# for repo in manager agent client common api_auth; do
#   cd $HOME/src/$repo
#   echo "* updating $repo"
#   git pull -q
# done

export TEST_ROOT=$(pwd)
cd $TEST_ROOT

# stop running daemons
# scripts/manager/stop.sh
# scripts/agent/stop.sh

# upgrade manager and agent
scripts/manager/upgrade.sh
scripts/agent/upgrade.sh

# overwrite god scripts
cp -a manager/*.god /var/www/bixby/current/config/deploy/god/

# run tests
cd tests
# bundle install --quiet
bundle exec micron

# temp debug
for f in `ls /var/www/bixby/current/log/*god*`; do
  cat $f
done
echo
sudo cat /var/log/syslog | grep god
echo
ps auxwwf

# workaround for weird bug where exit code gets overwritten and always returns 0 instead
ret=$(cat .micron/last_run)
exit $ret
