#!/usr/bin/env bash

# stop current agent & cleanup
sudo /etc/init.d/bixby stop
sudo pkill -9 -u 0 -U 0 -f god
sudo pkill -9 -u 0 -U 0 -f bixby-agent
sudo pkill -9 -f bixby-mon

if [[ -d /opt/bixby/etc ]]; then
  sudo rm -rf /opt/bixby/etc
  sudo mkdir -p /opt/bixby/etc
  sudo chown bixby:bixby /opt/bixby/etc
fi

if [[ -d /opt/bixby/var ]]; then
  sudo rm -rf /opt/bixby/var/*
fi
