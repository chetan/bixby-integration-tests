
require 'helper'
require 'awesome_print'

module Bixby
class Integration::UI::Monitoring < Bixby::Test::LoggedInUITestCase

  def test_view_monitoring_for_host

    visit url()
    assert_selector_i "div.host_list div.host div.actions a.monitoring"
    find("div.host_list div.host div.actions a.monitoring").click

    wait_for_state("mon_view_host", 30)

    assert find("h3").text =~ /Resources for bixbytest/

    checks = Bixby::Model::Check.list(1)
    ap checks

    checks.each do |check|
      assert_selector_i "div.check[check_id='#{check.id}']"
      assert_selector_i "div.check[check_id='#{check.id}'] div.metric div.graph_container div.graph"
      assert_selector_i "div.check[check_id='#{check.id}'] div.metric div.graph_container div.graph canvas"
      assert page.evaluate_script("testGraphs(#{check.id});")
    end

    flunk
  end

end
end
