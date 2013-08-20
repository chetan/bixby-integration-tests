#!/usr/bin/env bash

ROOT=$(dirname $(readlink -f $0))
cd $ROOT

REPOS="manager agent client common"

mkdir -p src
if [ -d $ROOT/src/manager ]; then
  # git pull
  for repo in $REPOS; do
    cd $ROOT/src/$repo
    echo "* updating $repo"
    git pull -q >/dev/null
  done

else
  # git clone
  cd $ROOT/src
  for repo in $REPOS; do
    echo "* cloning $repo"
    git clone -q https://github.com/chetan/bixby-$repo.git $repo >/dev/null
  done
fi

# update manager gem cache
cd $ROOT/src/manager
echo "* updating manager gem cache"
bundle package --all >/dev/null

# make sure we have libv8 avail for linux
# https://rubygems.org/downloads/libv8-3.11.8.17-x86_64-linux.gem
cd $ROOT/src/manager/vendor/cache
v8=`ls libv8* | grep darwin | xargs basename | perl -ne 's/-x86.*$//g; print $_'`
ver="$v8-x86_64-linux"
if [ ! -f $ver.gem ]; then
  url="https://rubygems.org/downloads/$ver.gem"
  wget -q $url
fi

# update test gem cache
cd $ROOT/tests
echo "* updating test gem cache"
bundle package --all >/dev/null
