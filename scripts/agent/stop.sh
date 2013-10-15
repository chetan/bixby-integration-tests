#!/usr/bin/env bash

# stop current agent & cleanup
sudo /etc/init.d/bixby stop
sudo pkill -9 -u 0 -U 0 -f god
sudo pkill -9 -u 0 -U 0 -f bixby-agent
sudo pkill -9 -f mon_daemon
cd /opt/bixby/etc
sudo rm -f bixby.yml id_rsa server.pub god.d/m*.god
cd ../var/
sudo rm -rf *
