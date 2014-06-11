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
  echo "* upgrading $proj gem in /opt/bixby"
  cd /opt/bixby-integration/src/$proj
  # git reset --hard
  git pull -q

  rm -rf pkg *.gem
  # $shim bundle install --without development test
  gem build *.gemspec 2>/dev/null
  sudo $shim gem install *.gem --no-ri --no-rdoc --local >/dev/null
done

# properly install runtime deps from git
# currently only api-auth is from git
echo
echo "* upgrading api-auth in /opt/bixby"
cd /opt/bixby-integration/src
if [ ! -d api_auth ]; then
  git clone https://github.com/chetan/api_auth.git
fi
cd api_auth
git checkout -q bixby
git reset --hard -q
git pull -q
rm -rf pkg *.gem
gem build *.gemspec 2>/dev/null
sudo $shim gem install *.gem --no-ri --no-rdoc --local >/dev/null

# upgrade repo
cd /opt/bixby/repo/
sudo rm -rf vendor
sudo wget -q https://s3.bixby.io/repo/repo-$(curl -sL s3.bixby.io/latest-repo).tar.gz
sudo tar -xzf repo-*.tar.gz
sudo mv bixby-repo vendor
sudo chown -R bixby:bixby vendor
sudo rm -f *.gz
