#!/usr/bin/env bash

# vagrant will run this script as root (via sudo)
# so instead we run shim.sh via vagrant's provisioner which in turn will
# run this script as a non-root user (vagrant)

export http_proxy="http://192.168.80.98:8000"

setup http proxy for apt
if [[ ! -f /etc/apt/apt.conf.d/30apt-proxy ]]; then
  echo "Acquire { Retries \"0\"; HTTP { Proxy \"$http_proxy\"; }; };" > /tmp/30apt-proxy
  sudo mv /tmp/30apt-proxy /etc/apt/apt.conf.d
fi

sudo apt-get -qq update
sudo apt-get -qq -y install git ruby rubygems libcurl4-openssl-dev libmemcache-dev \
  libsasl2-dev libmysqlclient-dev build-essential python-software-properties \
  libpq-dev postgresql-9.1 postgresql-client-common curl most htop vim-nox \
  gawk libyaml-dev libsqlite3-dev sqlite3 autoconf libgdbm-dev libncurses5-dev \
  automake libtool bison libffi-dev

sudo add-apt-repository -y ppa:nginx/stable
sudo add-apt-repository -y ppa:chris-lea/redis-server
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/10gen.list

sudo apt-get -qq update
sudo apt-get -qq -y install mongodb-10gen redis-server nginx

sudo gem install god --no-ri --no-rdoc
\curl -L https://get.rvm.io | bash -s stable --ruby

source /home/vagrant/.rvm/scripts/rvm

# setup psql
sudo su - postgres -c 'psql -c "CREATE USER vagrant WITH SUPERUSER;"'
echo "local   all             vagrant                                peer" \
  | sudo cat /etc/postgresql/9.1/main/pg_hba.conf - | sudo tee /etc/postgresql/9.1/main/pg_hba.conf

# setup nginx
sudo cp /opt/bixby-integration/manager/nginx.conf /etc/nginx/sites-enabled/bixby
sudo rm -f /etc/nginx/sites-enabled/default
sudo service nginx restart

# should be on ruby-2.0.0-p247 or later by default



# install manager
echo "export RAILS_ENV=staging" >> ~/.bashrc
export RAILS_ENV=staging
sudo mkdir -p /var/www/bixby/shared/log /var/www/bixby/shared/bixby /var/www/bixby/shared/pids /var/www/bixby/current
sudo chown -R vagrant:vagrant /var/www/bixby

if [ -d /var/www/bixby/current/.git ]; then
  cd /var/www/bixby/current
  git pull
else
  git clone https://github.com/chetan/bixby-manager.git /var/www/bixby/current
  cd /var/www/bixby/current
fi

mkdir -p tmp
cd tmp
ln -sf /var/www/bixby/shared/pids .
cd ..
ln -sf /var/www/bixby/shared/log .

bundle install
cd config
cp -a /opt/bixby-integration/manager/database.yml .
cp -a /opt/bixby-integration/manager/bixby.yml .
cd ..
mkdir -p log

rake db:setup bixby:update_repos
# assets not compiling for some reason
# assets:clobber assets:precompile

sudo RAILS_ENV=staging god -c /var/www/bixby/current/config/deploy/bixby.god



# install and register agent
\curl -sL https://get.bixby.io | bash -s pixelcop http://localhost

unset http_proxy
sudo /opt/bixby/bin/bixby-agent -P test -t pixelcop --tags tag1,tag2 -- http://localhost
