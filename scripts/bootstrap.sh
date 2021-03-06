#!/usr/bin/env bash

# vagrant will run this script as root (via sudo)
# so instead we run shim.sh via vagrant's provisioner which in turn will
# run this script as a non-root user (vagrant)

# possibly useful for development to speed up bootstrapping
# export http_proxy="http://192.168.80.98:8000"
# export https_proxy="http://192.168.80.98:8001"

# make sure bind mount is up
sudo mount -a

# already been bootstrapped
if [ -d /opt/bixby ]; then
  exit
fi

# set timezone
echo "America/New_York" > tz
sudo mv tz /etc/timezone
sudo cp -a $(readlink -f /usr/share/zoneinfo/US/Eastern) /etc/localtime

# make sure curl/wget work with HTTPS intercept
echo insecure > $HOME/.curlrc
echo check_certificate=off > $HOME/.wgetrc

echo 'source $HOME/.bashrc' >> $HOME/.bash_profile

# fix apt-get issues:
# stdin: is not a tty
# dpkg-preconfigure: unable to re-open stdin: No such file or directory
export DEBIAN_FRONTEND=noninteractive

# setup http proxy for apt
if [[ ! -z "$http_proxy" ]] && [[ ! -f /etc/apt/apt.conf.d/30apt-proxy ]]; then
  echo "Acquire { Retries \"0\"; HTTP { Proxy \"$http_proxy\"; }; };" > /tmp/30apt-proxy
  sudo mv /tmp/30apt-proxy /etc/apt/apt.conf.d
fi

sudo apt-get -qq update
sudo DEBIAN_FRONTEND=noninteractive apt-get -qqy -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
sudo apt-get -qq -y install git ruby rubygems libcurl4-openssl-dev libmemcache-dev \
  libsasl2-dev libmysqlclient-dev build-essential python-software-properties \
  libpq-dev postgresql-9.1 postgresql-client-common curl most htop vim-nox \
  gawk libyaml-dev libsqlite3-dev sqlite3 autoconf libgdbm-dev libncurses5-dev \
  automake libtool bison libffi-dev screen libxml2-dev libxslt1-dev \
  libssl-dev libfontconfig1-dev

sudo add-apt-repository -y ppa:nginx/stable
sudo add-apt-repository -y ppa:chris-lea/redis-server
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/10gen.list > /dev/null

sudo apt-get -qq update
sudo apt-get -qq -y install mongodb-10gen redis-server nginx

sudo gem install god --no-ri --no-rdoc
\curl -L https://get.rvm.io | bash -s stable --ruby=2.1.2

source $HOME/.rvm/scripts/rvm

# couple basic configs
cd $HOME
wget https://gist.github.com/chetan/4958387/raw/2e4510853a26af9a6a9a1742f2e4df2ef25f7b81/.vimrc
cp /opt/bixby-integration/etc/.screenrc .

# setup psql
sudo su - postgres -c 'psql -c "CREATE USER vagrant WITH SUPERUSER;"'
echo "local   all             vagrant                                peer" \
  | sudo cat /etc/postgresql/9.1/main/pg_hba.conf - | sudo tee /etc/postgresql/9.1/main/pg_hba.conf > /dev/null

# setup nginx
sudo rm -f /etc/nginx/sites-enabled/*
sudo cp /opt/bixby-integration/manager/nginx/nginx.conf /etc/nginx/nginx.conf
sudo cp /opt/bixby-integration/manager/nginx/bixby.conf /etc/nginx/sites-enabled/bixby.conf
sudo service nginx restart

# install phantomjs
cd /tmp
wget -nv https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.7-linux-x86_64.tar.bz2
tar -xjf phantom*.bz2
sudo cp -a phantom*/bin/phantomjs /usr/local/bin/
rm -rf phantomjs*

# unset so we don't interfere with github
unset http_proxy
unset https_proxy


################################################################################
# checkout source repos
mkdir -p $HOME/src
cd $HOME/src
for proj in common client agent manager; do
  git clone https://github.com/chetan/bixby-$proj.git $proj
done
git clone https://github.com/chetan/api_auth.git
cd api_auth
git checkout -qb bixby origin/bixby

# setup integration test env
cd /opt/bixby-integration/tests
bundle install


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
sudo mkdir -p $current
echo "/home/vagrant/src/manager  /var/www/bixby/current   none   defaults,bind  0 0" | cat /etc/fstab - | sudo tee /etc/fstab > /dev/null
sudo mount -a
cd $current
mkdir -p tmp
ln -sf $shared/pids $current/tmp/
ln -sf $shared/log $current/
