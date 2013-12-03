#!/usr/bin/env bash

shim=/opt/bixby-integration/scripts/agent-shim

# upgrade bundler if needed
/opt/bixby-integration/scripts/upgrade_bundler.sh

# uninstall previous gem
echo "* uninstall existing bixby gems"
for proj in agent client common; do
  yes | sudo $shim gem uninstall bixby-$proj -axq > /dev/null
done

for proj in common client agent; do
  echo "* updating $proj"
  cd /opt/bixby-integration/src/$proj
  # git reset --hard
  git pull -q

  rm -rf pkg *.gem
  # $shim bundle install --without development test
  gem build *.gemspec >/dev/null
  sudo $shim gem install *.gem --no-ri --no-rdoc --local >/dev/null
done

# properly install runtime deps from git
# currently only api-auth is from git
echo
echo "* installing api-auth"
cd /opt/bixby-integration/src
if [ ! -d api_auth ]; then
  git clone https://github.com/chetan/api_auth.git
fi
cd api_auth
git checkout -q bixby
git reset --hard -q
git pull -q
rm -rf pkg *.gem
gem build *.gemspec >/dev/null
sudo $shim gem install *.gem --no-ri --no-rdoc --local >/dev/null

# other agent stuff
# init
cd /opt/bixby-integration/src/agent/etc
sudo cp -a bixby-god.initd /etc/init.d/bixby
sudo chmod 755 /etc/init.d/bixby
# god config
sudo mkdir -p /opt/bixby/
sudo cp -a bixby.god god.d /opt/bixby/etc/

# cleanup
sudo chown -R bixby:bixby /opt/bixby
