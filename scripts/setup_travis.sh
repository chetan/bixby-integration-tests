
TEST_ROOT=$(pwd)

sudo apt-get -qq update
sudo apt-get install nginx
sudo gem install god --no-ri --no-rdoc

# setup nginx
sudo rm -f /etc/nginx/sites-enabled/*
sudo cp $TEST_ROOT/manager/nginx/nginx.conf /etc/nginx/nginx.conf
sudo cp $TEST_ROOT/manager/nginx/bixby.conf /etc/nginx/sites-enabled/bixby.conf
sudo service nginx restart

mkdir -p $HOME/src
cd $HOME/src
for proj in common client agent manager; do
  git clone https://github.com/chetan/bixby-$proj.git $proj
done
git clone https://github.com/chetan/api_auth.git
cd api_auth
git checkout -qb bixby origin/bixby

# install test deps
cd $TEST_ROOT/tests
bundle install --deployment


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
sudo mkdir -p $bixby
sudo cp -a $HOME/src/manager $current
cd $current
mkdir -p tmp
ln -sf $shared/pids $current/tmp/
ln -sf $shared/log $current/
