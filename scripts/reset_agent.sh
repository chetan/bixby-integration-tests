#!/usr/bin/env bash

shim=/opt/bixby-integration/scripts/agent-shim

/opt/bixby-integration/scripts/upgrade_bundler.sh

# uninstall previous gem
for proj in common client agent; do
  yes | sudo $shim gem uninstall bixby-$proj -axq
done

for proj in common client agent; do
  echo
  echo "* updating $proj"
  echo
  cd /opt/bixby-integration/src/$proj
  git reset --hard
  git pull

  rm -rf pkg *.gem
  # $shim bundle install --without development test
  $shim gem build *.gemspec
  sudo $shim gem install *.gem --no-ri --no-rdoc
done

# properly install deps from git
echo
echo "* installing api-auth"
echo
cd /opt/bixby-integration/src/agent
cd `$shim bundle show api-auth`
rm -rf pkg *.gem
$shim gem build *.gemspec
sudo $shim gem install *.gem --no-ri --no-rdoc
