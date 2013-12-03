
# init
cd /opt/bixby-integration/src/agent/etc
sudo cp -a bixby-god.initd /etc/init.d/bixby
sudo chmod 755 /etc/init.d/bixby

# god config
sudo mkdir -p /opt/bixby/
sudo cp -a bixby.god god.d /opt/bixby/etc/

# cleanup
sudo chown -R bixby:bixby /opt/bixby
