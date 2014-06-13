
require 'helper'

module Bixby
class Integration::Monitoring < Bixby::Test::AgentTestCase

  def setup
    super
    @commands = Bixby::Model::Command.list
    @start_time = Time.new
    @pid = mon_pid()
  end

  def test_reset_checks
    Bixby::Model::Check.list(1).each do |check|
      assert Bixby::Model::Check.destroy(check.id)
    end
    assert_empty Bixby::Model::Check.list(1)
    Bixby::Monitoring.update_check_config(1)
  end

  def test_add_first_check_cpu_load

    cmd = {
      :repo    => "vendor",
      :bundle  => "hardware/cpu",
      :command => "monitoring/cpu_load.rb",
    }
    check = add_check(cmd, nil)

    assert check
    assert check["name"] =~ /load average/i
    assert_empty check["args"]

    update_check_config()

    # check should have been written to config.json as well, verify it
    cmd[:id] = check.id
    verify_check_config(cmd)
  end

  # list of checks to test
  checks = [
    {
      :name    => "cpu usage",
      :repo    => "vendor",
      :bundle  => "hardware/cpu",
      :command => "monitoring/cpu_usage.rb",
    },
    {
      :name    => "disk usage",
      :repo    => "vendor",
      :bundle  => "hardware/storage",
      :command => "monitoring/disk_usage.rb",
    },
    {
      :name    => "inode usage",
      :repo    => "vendor",
      :bundle  => "hardware/storage",
      :command => "monitoring/inode_usage.rb",
    },
    {
      :name    => "port check",
      :repo    => "vendor",
      :bundle  => "hardware/network",
      :command => "monitoring/port_check.rb",
      :args    => {:port => "localhost:80"}
    },
    {
      :name    => "ping",
      :repo    => "vendor",
      :bundle  => "hardware/network",
      :command => "monitoring/ping.rb",
      :args    => {:host => "localhost"}
    },
    {
      :name    => "network connections by type",
      :repo    => "vendor",
      :bundle  => "hardware/network",
      :command => "monitoring/connection_count.rb",
      :args    => {:port => "80,22"}
    },
    {
      :name    => "network connections by state",
      :repo    => "vendor",
      :bundle  => "hardware/network",
      :command => "monitoring/connection_state.rb",
    },
    {
      :name => "process usage",
      :repo    => "vendor",
      :bundle  => "system/general",
      :command => "monitoring/process_usage.rb",
      :args => {:command_name => "mongod"}
    }
  ]

  # Create tests to add each check
  checks.each do |c|
    name, args = [ c.delete(:name), c.delete(:args) ]

    c[:command] =~ %r{/(.*?)\.rb$}
    m = $1
    define_method("test_add_#{m}".to_sym) do
      check = add_check(c, args)
      assert check
      c[:id] = check.id
      assert_includes check.name.downcase, name
      if args.nil? then
        assert_empty check.args
      else
        refute_empty check.args
        args.each do |k,v|
          assert_equal v, check.args[k.to_s], "arg #{k} has correct value"
        end
      end
    end
  end

  def test_update_check_config
    update_check_config()
  end

  # Create tests to verify each check
  checks.each do |c|
    c[:command] =~ %r{/(.*?)\.rb$}
    m = $1
    define_method("test_verify_config_#{m}") do
      verify_check_config(c)
    end
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
    command = @commands.find{ |c| c["repo"] == cmd[:repo] && c.bundle["path"] == cmd[:bundle] && c["command"] == cmd[:command] }
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


    # return a proper Check object
    return Bixby::Model::Check.find(data["id"])
  end

  # update check config and wait for mon daemon to restart
  def update_check_config()
    # force config update
    req = JsonRequest.new("monitoring:update_check_config", [@agent_id])
    res = Bixby.client.exec_api(req)
    assert res
    assert res.success?

    assert wait_for_file_change("/opt/bixby/etc/monitoring/config.json", @start_time, 10)
    sleep 0.2 # small delay to avoid race while file being written
    wait_for_mon_daemon_restart()
  end

  # Verify that the check config for the given command/check is present
  def verify_check_config(cmd)
    mon_config = MultiJson.load(File.read("/opt/bixby/etc/monitoring/config.json"))
    assert_kind_of Array, mon_config

    mon_config = mon_config.find{ |c| MultiJson.load(c["command"]["stdin"])["check_id"] == cmd[:id] }

    assert_equal 60, mon_config["retry"]
    assert_equal 60, mon_config["interval"]
    assert_equal cmd[:repo], mon_config["command"]["repo"]
    assert_equal cmd[:bundle], mon_config["command"]["bundle"]
    assert_equal cmd[:command], mon_config["command"]["command"]
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
