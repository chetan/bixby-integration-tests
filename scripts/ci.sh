#!/bin/bash

set -ex

cd /opt/bixby-integration
scripts/manager/upgrade.sh
scripts/agent/upgrade.sh

cd tests
bundle install
micron
