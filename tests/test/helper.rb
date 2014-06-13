
root = File.expand_path(File.dirname(__FILE__))
if not $:.include? root then
  # add to library load path
  $: << root
end
$: << File.join(File.dirname(root), "lib")

require "rubygems"
if not defined? ::Bundler then
  require "bundler/setup"
end

EasyCov.path = "coverage"
EasyCov.filters << EasyCov::IGNORE_GEMS << EasyCov::IGNORE_STDLIB
EasyCov.filters << lambda { |filename|
  # ignore vendored files
  filename !~ %r(#{EasyCov.root}/vendor/)
}
EasyCov.start

require "micron/minitest"

# disable logging
require "httpi"
HTTPI.log = false

require "oj" # make sure we are using oj for multi_json
require "setup/base"
require "setup/agent_test_case"
require "setup/ui_test_case"
require "setup/logged_in_ui_test_case"
