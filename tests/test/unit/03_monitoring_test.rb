
require 'helper'

module Bixby
class Integration::Monitoring < Bixby::Test::AgentTestCase

  def setup
    super
    @commands = Bixby::Model::Command.list
    @start_time = Time.new
    @pid = mon_pid()
  end

  def test_add_first_check_cpu_load

    check = add_check({
      :repo    => "vendor",
      :bundle  => "hardware/cpu",
      :command => "monitoring/cpu_load.rb",
    }, nil)

    assert check
    assert check["name"] =~ /load average/i
    assert_empty check["args"]

    wait_for_mon_daemon_restart()
  end

  def test_add_cpu_usage

    check = add_check({
      :repo    => "vendor",
      :bundle  => "hardware/cpu",
      :command => "monitoring/cpu_usage.rb",
    }, nil)

    assert check
    assert check["name"] =~ /cpu usage/i
    assert_empty check["args"]

    wait_for_mon_daemon_restart()
  end

  def test_add_disk_usage

    check = add_check({
      :repo    => "vendor",
      :bundle  => "hardware/storage",
      :command => "monitoring/disk_usage.rb",
    }, nil)

    assert check
    assert check["name"] =~ /disk usage/i
    assert_empty check["args"]

    wait_for_mon_daemon_restart()
  end

  def test_add_inode_usage

    check = add_check({
      :repo    => "vendor",
      :bundle  => "hardware/storage",
      :command => "monitoring/inode_usage.rb",
    }, nil)

    assert check
    assert check["name"] =~ /inode usage/i
    assert_empty check["args"]

    wait_for_mon_daemon_restart()
  end

  def test_add_port_check

    check = add_check({
      :repo    => "vendor",
      :bundle  => "hardware/network",
      :command => "monitoring/port_check.rb",
    }, {:port => "localhost:80"})

    assert check
    assert check["name"] =~ /port check/i
    refute_empty check["args"]
    assert_equal "localhost:80", check["args"]["port"]

    wait_for_mon_daemon_restart()
  end

  def test_add_ping

    check = add_check({
      :repo    => "vendor",
      :bundle  => "hardware/network",
      :command => "monitoring/ping.rb",
    }, {:host => "localhost"})

    assert check
    assert check["name"] =~ /ping/i
    refute_empty check["args"]
    assert_equal "localhost", check["args"]["host"]

    wait_for_mon_daemon_restart()
  end

  def test_add_connection_count

    check = add_check({
      :repo    => "vendor",
      :bundle  => "hardware/network",
      :command => "monitoring/connection_count.rb",
    }, {:port => "80,22"})

    assert check
    refute_empty check["args"]
    assert_equal "80,22", check["args"]["port"]

    wait_for_mon_daemon_restart()
  end

  def test_add_connection_state

    check = add_check({
      :repo    => "vendor",
      :bundle  => "hardware/network",
      :command => "monitoring/connection_state.rb",
    }, nil)

    assert check
    assert_empty check["args"]

    wait_for_mon_daemon_restart()
  end

  def test_add_process_usage

    check = add_check({
      :repo    => "vendor",
      :bundle  => "system/general",
      :command => "monitoring/process_usage.rb",
    }, {:command_name => "mongod"})

    assert check
    refute_empty check["args"]
    assert_equal "mongod", check["args"]["command_name"]

    wait_for_mon_daemon_restart()
  end

  # Test a direct call to update check API
  def test_update_check_config

    req = JsonRequest.new("monitoring:update_check_config", [@agent_id])
    res = Bixby.client.exec_api(req)
    assert res
    assert res.success?

    assert wait_for_file_change("/opt/bixby/etc/monitoring/config.json", @start_time, 10)

    wait_for_mon_daemon_restart()
  end



  private

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
    timeout(20) {
      while true do
        break if !mon_pid.nil?
      end
    }
  end

  # Wait for the monitoring daemon to restart
  def wait_for_mon_daemon_restart(old_pid=nil)
    old_pid ||= @pid
    timeout(60, "waiting for mon daemon to restart (current pid=#{old_pid})") {
      while true do
        sleep 0.1
        new_pid = mon_pid()
        next if new_pid.nil?
        break if new_pid != old_pid
      end
    }
  end

  # Get the PID of the monitoring daemon
  #
  # @return [Fixnum] PID, if process exists
  # @raise [Assertion] thrown if more than 1 process found running
  def mon_pid
    shell = systemu("ps auxw | grep -v grep | grep bixby-monitoring-daemon")
    lines = shell.stdout.split(/\n/).reject{ |s| s.empty? }
    return nil if lines.empty?
    lines = lines.map{ |s| s.split(/\s+/) }
    lines.reject!{ |l| l.first != "bixby" || l.last != "bixby-monitoring-daemon" }
    if lines.size > 1 then
      raise Micron::Assertion, "Found #{lines.size} monitoring daemons running!", caller
    end
    ps = lines.first
    return ps[1].to_i
  end


end
end
