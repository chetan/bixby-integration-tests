#!/usr/bin/env bash

shim=/opt/bixby-integration/scripts/agent-shim

# upgrade bundler if needed
/opt/bixby-integration/scripts/upgrade_bundler.sh

# uninstall previous gem
echo "* uninstall existing bixby gems"
for proj in agent client common; do
  yes | sudo $shim gem uninstall bixby-$proj -axq > /dev/null
done

for proj in common client agent api_auth; do
  echo "* upgrading $proj gem in /opt/bixby"
  cd $HOME/src/$proj
  rm -rf pkg *.gem
  gem build *.gemspec 2>/dev/null

  if [[ "$proj" == "agent" ]]; then
    sudo $shim bundle install --quiet --without development test
  fi

  sudo $shim gem install *.gem --no-ri --no-rdoc --local >/dev/null
done

# upgrade repo
cd /opt/bixby/repo/
sudo rm -rf vendor
sudo wget -q https://s3.bixby.io/repo/repo-$(curl -sL s3.bixby.io/latest-repo).tar.gz
sudo tar -xzf repo-*.tar.gz
sudo mv bixby-repo vendor
sudo chown -R bixby:bixby vendor
sudo rm -f *.gz
