#!/bin/bash

set -e
unset cd
set -x

###
# cribbed from travis-build/lib/travis/build/script/templates/header.sh
RED="\033[31;1m"
GREEN="\033[32;1m"
RESET="\033[0m"

travis_retry() {
  set +e
  local result=0
  local count=1
  while [ $count -le 3 ]; do
    [ $result -ne 0 ] && {
      echo -e "\n${RED}The command \"$@\" failed. Retrying, $count of 3.${RESET}\n" >&2
    }
    "$@"
    result=$?
    [ $result -eq 0 ] && break
    count=$(($count + 1))
    sleep 1
  done

  [ $count -eq 3 ] && {
    echo "\n${RED}The command \"$@\" failed 3 times.${RESET}\n" >&2
  }

  set -e
  return $result
}
###


# /home/travis/build/chetan/bixby-integration-tests
TEST_ROOT=$( readlink -f $(dirname $(readlink -f $0))/.. )
sudo ln -s $TEST_ROOT /opt/bixby-integration

sudo add-apt-repository -y ppa:nginx/stable
sudo apt-get -qq update
sudo apt-get -qq install nginx ruby rubygems libevent-dev
sudo gem install god --quiet --no-ri --no-rdoc
sudo god check
exit 1

# setup nginx
sudo rm -f /etc/nginx/sites-enabled/*
sudo cp $TEST_ROOT/manager/nginx/nginx.conf /etc/nginx/nginx.conf
sudo cp $TEST_ROOT/manager/nginx/bixby.conf /etc/nginx/sites-enabled/bixby.conf
sudo service nginx restart

mkdir -p $HOME/src
cd $HOME/src
set +x
for proj in common client agent manager; do
  git clone --quiet https://github.com/chetan/bixby-$proj.git $proj
  cd $proj
  git log -1 --oneline | cat -
  cd ..
done
git clone --quiet https://github.com/chetan/api_auth.git
cd api_auth
git checkout -qb bixby origin/bixby
set -x

# install test deps
cd $TEST_ROOT/tests
travis_retry ~/wad


################################################################################
# install agent
\curl -sL https://get.bixby.io | bash -s


################################################################################
# install manager

echo "export RAILS_ENV=integration" >> ~/.bashrc

bixby=/var/www/bixby
shared=$bixby/shared
current=$bixby/current

echo "creating $bixby"
sudo mkdir -p $bixby
sudo cp -a $HOME/src/manager $current
cd $current
mkdir -p tmp
ln -sf $shared/pids $current/tmp/
ln -sf $shared/log $current/
travis_retry ~/wad
