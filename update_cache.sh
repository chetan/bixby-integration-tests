#!/usr/bin/env bash

cd $(dirname $(readlink -f $0))
if [ ! -d ../manager ]; then
  echo "can't locate manager source"
  exit 1
fi

mkdir -p src
if [ -d src/manager ]; then
  cd src/manager
  echo "* updating manager"
  git pull >/dev/null
  cd ../agent
  echo "* updating agent"
  git pull >/dev/null
  cd ../..
else
  cd src
  echo "* cloning manager"
  git clone ../../manager manager >/dev/null
  echo "* cloning agent"
  git clone ../../agent agent >/dev/null
  cd ..
fi

cd src/manager
echo "* updating manager gem cache"
bundle package --all >/dev/null
cd ..
