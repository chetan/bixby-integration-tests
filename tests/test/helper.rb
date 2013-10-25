
def spork_running?
  ENV.include? "DRB"
end

def zeus_running?
  File.exists? '.zeus.sock' and Module.const_defined?(:Zeus)
end

def prefork
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

  if not(spork_running? or zeus_running?) then
    # load now if neither spork (DRB) or zeus are running
    # (usually during manual rake test run)
    load_simplecov()
  end

  require "test_guard"
  require "micron/minitest"
end

def load_simplecov
  EasyCov.path = "coverage"
  EasyCov.filters << EasyCov::IGNORE_GEMS << EasyCov::IGNORE_STDLIB
  EasyCov.filters << lambda { |filename|
    # ignore vendored files
    filename !~ %r(#{EasyCov.root}/vendor/)
  }
  EasyCov.start
end

def bootstrap_tests
  if spork_running? or zeus_running? then
    load_simplecov()
  end

  require "setup/base"
  require "setup/agent_test_case"
  require "setup/ui_test_case"
end

if Object.const_defined? :Spork then

  #uncomment the following line to use spork with the debugger
  #require 'spork/ext/ruby-debug'

  Spork.prefork do
    prefork()
  end

  Spork.each_run do
    bootstrap_tests()
  end

  # Spork.after_each_run do
  # end

elsif zeus_running? then
  prefork()

else
  # normal 'rake test'
  prefork()
  bootstrap_tests()

end
