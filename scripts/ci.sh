#!/bin/bash

set -ex

cd /opt/bixby-integration

scripts/manager/stop.sh
scripts/agent/stop.sh

scripts/manager/upgrade.sh
scripts/agent/upgrade.sh

cd tests
bundle install
bundle exec micron
