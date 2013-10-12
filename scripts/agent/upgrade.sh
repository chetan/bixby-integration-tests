#!/usr/bin/env bash

# make sure stopped before upgrade
/opt/bixby-integration/scripts/agent/stop.sh

shim=/opt/bixby-integration/scripts/agent-shim

# upgrade bundler if needed
/opt/bixby-integration/scripts/upgrade_bundler.sh

# uninstall previous gem
echo "* uninstall existing bixby gems"
for proj in agent client common; do
  yes | sudo $shim gem uninstall bixby-$proj -axq
done

for proj in common client agent; do
  echo
  echo "* updating $proj"
  echo
  cd /opt/bixby-integration/src/$proj
  # git reset --hard
  git pull

  rm -rf pkg *.gem
  # $shim bundle install --without development test
  gem build *.gemspec
  sudo $shim gem install *.gem --no-ri --no-rdoc --local
done

# properly install runtime deps from git
# currently only api-auth is from git
echo
echo "* installing api-auth"
echo
cd /opt/bixby-integration/src
if [ ! -d api_auth ]; then
  git clone https://github.com/chetan/api_auth.git
fi
cd api_auth
git checkout bixby
git reset --hard
git pull
rm -rf pkg *.gem
gem build *.gemspec
sudo $shim gem install *.gem --no-ri --no-rdoc --local
