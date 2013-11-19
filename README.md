
# Running the integration test suite

## On Host System

```bash
cd bixby-integration-tests
scripts/update_cache.sh
vagrant up
vagrant ssh
```

## On Guest System

```bash
cd /opt/bixby-integration
scripts/manager/stop.sh
scripts/agent/stop.sh

scripts/manager/upgrade.sh
scripts/agent/upgrade.sh

cd tests
bundle install
bundle exec micron
```
