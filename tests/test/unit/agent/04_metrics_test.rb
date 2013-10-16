
require 'helper'

module Bixby
class Integration::Agent::Metrics < Bixby::Test::AgentTestCase

  def setup
    super
    @commands = Bixby::Model::Command.list
    @start_time = Time.new
  end

  def test_metrics_for_all_checks

    sleep 10 # cheap hack for now; not sure how best to wait until metrics are in

    checks = Bixby::Model::Check.list(@agent_id)
    checks.each do |check|

      metrics = Bixby::Model::Metric.list_for_check(check.host_id, check.id)
      assert metrics
      refute_empty metrics
      metrics.each do |metric|
        p metric
        assert metric
        assert_equal "bixbytest", metric.tags["host"]
        assert_equal @agent_id, metric.tags["host_id"].to_i
        assert_equal check.id, metric.tags["check_id"].to_i
        refute_nil metric.last_value
      end

    end
  end

end
end
