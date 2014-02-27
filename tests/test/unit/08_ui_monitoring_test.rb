
require 'helper'

require 'awesome_print'

module Bixby
class Integration::UI::Monitoring < Bixby::Test::LoggedInUITestCase

  def test_verify_all_metric_graphs_for_host

    visit url()
    assert_selector_i "div.host_list div.host div.actions a.monitoring"
    find("div.host_list div.host div.actions a.monitoring").click

    wait_for_state("mon_view_host", 60) # really slow right now.. need to speed up mongo driver or switch to kairos

    assert find("h3").text =~ /Metrics for bixbytest/

    checks = Bixby::Model::Check.list(1)

    checks.each do |check|
      ap check
      assert_selector_i "div.check[check_id='#{check.id}']"
      assert_selector_i "div.check[check_id='#{check.id}'] div.metric div.graph_container div.graph"
      assert_selector_i "div.check[check_id='#{check.id}'] div.metric div.graph_container div.graph canvas"
      assert page.evaluate_script("testGraphs(#{check.id});")
    end
  end

  def test_view_metric_detail
    page.all("div.check div.metric a.metric").first.click
    wait_for_state("mon_hosts_metric")

    # test to see if more data was loaded
    #
    # only happens when more than 24h of data is available.. may need to
    # generate some data to test this
    # retry_for(10) {
    #   r = requests.last
    #   r.url =~ /downsample=5m-avg/ && !r.response_parts.empty?
    # }
    # assert_equal 200, requests.last.response_parts.last.status

    # graph is displayed
    assert_selector_i "div.metric.detail div.graph canvas"
  end

  def test_reset_checks
    Bixby::Model::Check.list(1).each do |check|
      assert Bixby::Model::Check.destroy(check.id)
    end
    assert_empty Bixby::Model::Check.list(1)

    Bixby::Monitoring.update_check_config(1)

    visit url("/monitoring/hosts/1")
    wait_for_state("mon_view_host")

    assert find("div.monitoring_content").text.include? "No checks have been configured"
  end


  ##############################################################################
  # Test adding each check

  def test_add_cpu_load
    add_check_command(nil, "CPU Load Average")
  end

  def test_add_cpu_usage
    add_check_command(nil, "CPU Usage")
  end

  def test_add_net_conn_count
    add_check_command(nil, "Network Connections by Type")
  end

  def test_add_net_conn_count_by_port
    add_check_command({:port => "80"}, "Network Connections by Port", "ARGS: PORT = 80")
  end

  def test_add_net_conn_state
    add_check_command(nil, "Network Connections by State")
  end

  def test_add_ping
    add_check_command({:host => "localhost"}, "Ping Test", "ARGS: HOST = LOCALHOST")
  end

  def test_add_port_check
    add_check_command({:port => 80}, "Port Check", "ARGS: PORT = 80")
    add_check_command({:port => "localhost:80"}, "Port Check", "ARGS: PORT = LOCALHOST:80")
  end

  def test_add_disk_usage
    add_check_command(nil, "Disk Usage", "ARGS: MOUNT = /") do
      select("/", :from => "mount")
    end
    add_check_command(nil, "Disk Usage", "ARGS: MOUNT = /BOOT") do
      select("/boot", :from => "mount")
    end
  end

  def test_add_inode_usage
    add_check_command(nil, "inode Usage", "ARGS: MOUNT = /") do
      select("/", :from => "mount")
    end
  end

  def test_add_process_memory_usage
    add_check_command({:command_name => "mongod"}, "Process Memory Usage", "ARGS: COMMAND_NAME = MONGOD")
  end


  private


  # Start monitoring the given check
  #
  # @param [Hash] opts          if nil, then no options are available
  # @param [String] check_name
  # @param [String] args        text which displays args in metrics info
  #
  # @return [Fixnum] ID of new check
  def add_check_command(opts, check_name, args=nil)
    visit url("/monitoring/hosts/1/checks/new")
    wait_for_state("mon_hosts_checks_new")

    id = find_check_id(check_name)

    page.all("label[for='command_id_#{id}']").first.click
    find("button#submit_check").click
    wait_for_state("mon_hosts_checks_new_opts")

    # h4 label
    assert_equal check_name, find("div.command_opts h4").text.strip

    # fill options or verify that no options are avail
    if block_given? then
      yield
    elsif opts.nil? then
      assert_equal "no options", find("div.no-opts").text.strip
    else
      fill(opts)
    end

    check_id = submit_options_and_verify(check_name, args)
  end

  def find_check_id(name)
    Bixby::Model::Command.list.each do |cmd|
      if cmd.name == name then
        return cmd.id
      end
    end
    nil
  end

  def submit_options_and_verify(name, args=nil)
    find("button#submit_check").click
    wait_for_state("mon_view_host", 30)

    checks = Bixby::Model::Check.list(1)
    assert_equal name, find("div.check[check_id='#{checks.last.id}'] h4").text.strip

    if not args.nil? then
      assert_equal args, find("div.check[check_id='#{checks.last.id}'] h5").text.strip
    end

    return checks.last.id
  end


end
end
