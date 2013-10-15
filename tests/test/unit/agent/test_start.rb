
require 'helper'

class Bixby::Integration::Agent::Start < Bixby::Test::TestCase

  def test_register_new_agent
    reset_manager
    reset_agent

    start_manager
    wait_for_manager

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

    agent_config = YAML.load_file("/opt/bixby/etc/bixby.yml")
    %w{manager_uri uuid mac_address access_key secret_key log_level}.each do |k|
      assert_includes agent_config, k
    end

    # verify host object was created
    hosts = Bixby::Model::Host.list
    assert hosts
    assert_kind_of Array, hosts
    assert_equal 1, hosts.size

    # verify host attributes
    h = hosts.first
    assert_equal 1, h["id"]
    assert_equal "bixbytest", h["hostname"]
    assert_equal "127.0.0.1", h["ip"]
    assert_equal "default", h["org"]
    assert_equal "new", h["tags"]
    assert_nil h["alias"]
    assert_nil h["desc"]

    # make sure logs have correct perms safter agent start
    shell = systemu("ls -l /opt/bixby/var/bixby-agent.log* | cut -f1 -d' '")
    shell.stdout.split(/\n/).each do |line|
      assert_equal "-rwxrwxrwx", line.strip
    end

  end

end

