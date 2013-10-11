#!/usr/bin/env bash

unset GEM_HOME GEM_PATH
unset MY_RUBY_HOME RUBY_VERSION

/opt/bixby/embedded/bin/gem list bundler -iv '>=1.3' >/dev/null
if [[ $? != 0 ]]; then
  sudo /opt/bixby/embedded/bin/gem install bundler --no-ri --no-rdoc
fi
