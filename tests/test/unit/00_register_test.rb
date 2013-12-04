
require 'helper'

class Bixby::Integration::Register < Bixby::Test::TestCase

  def test_register_new_agent
    reset_agent
    reset_manager

    start_manager
    wait_for_manager

    register_agent

    # wait a few secs for it to start fully
    wait_for_file("/opt/bixby/var/bixby-agent.pid", 5)

    %w(bixby.yml id_rsa server.pub).each do |f|
      f = "/opt/bixby/etc/#{f}"
      assert File.exists?(f), "#{f} exists"
      assert_equal 0, File.stat(f).uid, "#{f} owned by root"
    end

    %w(bixby.god god.d).each do |f|
      f = "/opt/bixby/etc/#{f}"
      assert File.exists?(f), "#{f} exists"
    end

    %w(bixby-agent.log bixby-agent.log.age bixby-agent.output bixby-agent.pid).each do |f|
      f = "/opt/bixby/var/#{f}"
      assert File.exists?(f), "#{f} exists"
      assert_equal 0, File.stat(f).uid, "#{f} owned by root"
    end

    agent_config = YAML.load_file("/opt/bixby/etc/bixby.yml")
    %w{manager_uri uuid mac_address access_key secret_key log_level}.each do |k|
      assert_includes agent_config, k, "bixby.yml includes #{k}"
      refute_nil agent_config[k], "bixby.yml key #{k} is not empty"
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
    assert_nil h["alias"]
    assert_nil h["desc"]

    tags = h["tags"].split(/,/)
    assert (tags.include?("new") && tags.include?("test"))

    # make sure logs have correct perms safter agent start
    shell = systemu("ls -l /opt/bixby/var/bixby-agent.log* | cut -f1 -d' '")
    shell.stdout.split(/\n/).each do |line|
      assert_equal "-rwxrwxrwx", line.strip
    end

  end

end

