
require 'helper'

require 'awesome_print'

module Bixby
class Integration::UI::Monitoring < Bixby::Test::LoggedInUITestCase

  def test_verify_all_metric_graphs_for_host

    visit url()
    assert_selector_i "div.host_list div.host div.actions a.monitoring"
    find("div.host_list div.host div.actions a.monitoring").click

    wait_for_state("mon_view_host", 60) # really slow right now.. need to speed up mongo driver or switch to kairos

    assert find("h3").text =~ /Resources for bixbytest/

    checks = Bixby::Model::Check.list(1)
    ap checks

    checks.each do |check|
      assert_selector_i "div.check[check_id='#{check.id}']"
      assert_selector_i "div.check[check_id='#{check.id}'] div.metric div.graph_container div.graph"
      assert_selector_i "div.check[check_id='#{check.id}'] div.metric div.graph_container div.graph canvas"
      assert page.evaluate_script("testGraphs(#{check.id});")
    end
  end

  def test_view_metric_detail
    find("div.check[check_id='1'] div.metric[metric_id='1'] a.metric").click
    wait_for_state("mon_hosts_resources_metric")

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
    assert_selector_i "div.metric.detail[metric_id='1'] div.graph canvas"
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
    add_check_command(1, nil, "CPU Load Average")
  end

  def test_add_cpu_usage
    add_check_command(2, nil, "CPU Usage")
  end

  def test_add_conn_count
    add_check_command(3, {:port => "80"}, "Network Connections by Type", "PORT = 80")
  end


  private


  # Start monitoring the given check
  #
  # @param [Fixnum] id          Command ID
  # @param [Hash] opts          if nil, then no options are available
  # @param [String] check_name
  # @param [String] args        text which displays args in metrics info
  #
  # @return [Fixnum] ID of new check
  def add_check_command(id, opts, check_name, args=nil)
    visit url("/monitoring/hosts/1/checks/new")
    wait_for_state("mon_hosts_resources_new")

    page.all("label[for='command_id_#{id}']").first.click
    find("a#submit_check").click
    wait_for_state("mon_hosts_resources_new_opts")

    if opts.nil? then
      assert_equal "no options", find("div.command_opts div").text.strip
    else
      fill(opts)
    end

    check_id = submit_options_and_verify(check_name, args)
  end

  def submit_options_and_verify(name, args=nil)
    find("a#submit_check").click
    wait_for_state("mon_view_host")

    checks = Bixby::Model::Check.list(1)
    assert_equal name, find("div.check[check_id='#{checks.last.id}'] h4").text.strip

    if not args.nil? then
      assert_equal args, find("div.check[check_id='#{checks.last.id}'] h5").text.strip
    end

    return checks.last.id
  end


end
end
