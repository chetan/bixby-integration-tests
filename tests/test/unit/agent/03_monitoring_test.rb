
require 'helper'

module Bixby
class Integration::Agent::Monitoring < Bixby::Test::AgentTestCase

  def setup
    super
    @commands = Bixby::Model::Command.list
    @start_time = Time.new
  end

  # Add the given command as a new check and return it
  #
  # @param [Hash] cmd
  # @param [Hash] args
  #
  # @return [Hash] check
  def add_check(cmd, args=nil)

    # find the command
    cmd[:repo] ||= "vendor"
    command = @commands.find{ |c| c["repo"] == cmd[:repo] && c["bundle"] == cmd[:bundle] && c["command"] == cmd[:command] }
    assert command

    # add_check call to manager
    req = JsonRequest.new("monitoring:add_check", [@agent_id, command["id"], args])
    res = Bixby.client.exec_api(req)
    assert res
    assert res.success?

    # check was returned, verify it
    data = res.data
    assert data
    refute_nil data["id"]
    assert_equal @agent_id, data["host_id"]
    assert_equal @agent_id, data["agent_id"]
    assert_equal command["id"], data["command_id"]
    assert data["enabled"]
    assert_empty data["args"]

    # check should have been written to config.json as well, verify it
    assert wait_for_file_change("/opt/bixby/etc/monitoring/config.json", @start_time, 10)
    sleep 0.2 # small delay to avoid race while file being written
    mon_config = MultiJson.load(File.read("/opt/bixby/etc/monitoring/config.json"))
    assert_kind_of Array, mon_config
    mon_config = mon_config.last
    assert_equal 60, mon_config["retry"]
    assert_equal 60, mon_config["interval"]
    assert_equal cmd[:repo], mon_config["command"]["repo"]
    assert_equal cmd[:bundle], mon_config["command"]["bundle"]
    assert_equal cmd[:command], mon_config["command"]["command"]

    data
  end

  # Wait for the monitoring daemon to come up
  def wait_for_mon_daemon
    timeout(10) {
      while true do
        shell = systemu("ps auxw | grep -v grep | grep mon_daemon.rb")
        next if shell.stdout.empty?
        ps = shell.stdout.split(/\s+/)

        break if ps.last == "mon_daemon.rb" && ps.first == "bixby"
      end
    }
  end

  def test_add_first_check_cpu_load

    check = add_check({
      :repo    => "vendor",
      :bundle  => "hardware/cpu",
      :command => "monitoring/cpu_load.rb",
    }, nil)

    assert check
    assert check["name"] =~ /load average/i

    wait_for_mon_daemon()
  end

  def test_add_cpu_usage

    check = add_check({
      :repo    => "vendor",
      :bundle  => "hardware/cpu",
      :command => "monitoring/cpu_usage.rb",
    }, nil)

    assert check
    assert check["name"] =~ /cpu usage/i

    wait_for_mon_daemon()
  end

  def test_add_disk_usage

    check = add_check({
      :repo    => "vendor",
      :bundle  => "hardware/storage",
      :command => "monitoring/disk_usage.rb",
    }, nil)

    assert check
    assert check["name"] =~ /disk usage/i

    wait_for_mon_daemon()
  end

  def test_add_inode_usage

    check = add_check({
      :repo    => "vendor",
      :bundle  => "hardware/storage",
      :command => "monitoring/inode_usage.rb",
    }, nil)

    assert check
    assert check["name"] =~ /inode usage/i

    wait_for_mon_daemon()
  end

  # Test a direct call to update check API
  def test_update_check_config

    shell = systemu("ps auxw | grep -v grep | grep mon_daemon.rb")
    ps = shell.stdout.split(/\s+/)
    pid = ps[1]

    req = JsonRequest.new("monitoring:update_check_config", [@agent_id])
    res = Bixby.client.exec_api(req)
    p res
    assert res
    assert res.success?

    assert wait_for_file_change("/opt/bixby/etc/monitoring/config.json", @start_time, 10)

    # mon_daemon should restart
    timeout(10) {
      while true do
        shell = systemu("ps auxw | grep -v grep | grep mon_daemon.rb")
        next if shell.stdout.empty?
        ps = shell.stdout.split(/\s+/)

        # check for pid change
        break if ps.last == "mon_daemon.rb" && ps.first == "bixby" && ps[1] != pid
      end
    }
  end

end
end
