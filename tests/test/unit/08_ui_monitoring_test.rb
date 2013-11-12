
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
    retry_for(5) {
      requests.last.url =~ /downsample=5m-avg/ && !requests.last.response_parts.empty?
    }
    assert_equal 200, requests.last.response_parts.last.status

    # graph is displayed
    assert_selector_i "div.metric.detail[metric_id='1'] div.graph canvas"
  end

end
end
