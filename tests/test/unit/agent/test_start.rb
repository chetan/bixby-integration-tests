
require 'helper'

class Bixby::Integration::Agent::Start < Bixby::Test::TestCase

  def test_register_new_agent

    reset_manager
    reset_agent

    start_manager
    wait_for_manager

    req = http_get("http://localhost/")

    register_agent

    %w(bixby.yml id_rsa server.pub).each do |f|
      f = "/opt/bixby/etc/#{f}"
      assert File.exists?(f), "#{f} exists"
      assert_equal 0, File.stat(f).uid, "#{f} owned by root"
    end

    %w(bixby-agent.log bixby-agent.log.age bixby-agent.output bixby-agent.pid).each do |f|
      f = "/opt/bixby/var/#{f}"
      assert File.exists?(f), "#{f} exists"
      assert_equal 0, File.stat(f).uid, "#{f} owned by root"
    end

    flunk
  end

end

