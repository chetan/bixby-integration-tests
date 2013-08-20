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

# update test gem cache
cd $ROOT
echo "* updating test gem cache"
bundle package --all >/dev/null
