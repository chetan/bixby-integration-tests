
require 'helper'
require 'sidekiq'

module Bixby
class Integration::Metrics < Bixby::Test::AgentTestCase

  def test_metrics_for_all_checks

    # wait for sidekiq jobs to flush...
    # crude and hackish.. yech
    ts = Time.new
    stats = nil
    timeout(120) {
      while true do
        stats = Sidekiq::Stats.new
        puts "queued = #{stats.queues['schedules']}"
        puts "processed = #{stats.processed}"
        if stats.queues["schedules"] == 0 && stats.processed >= 5 then
          # processed should be 5 because we need at least 2 reports from the mon daemon for some
          # checks to report metrics
          break
        end
        sleep 1
      end
    }

    checks = Bixby::Model::Check.list(@agent_id)
    checks.each do |check|
      puts
      p check

      metrics = Bixby::Model::Metric.list_for_check(check.host_id, check.id)
      refute_empty metrics, "have metrics for check (#{check.name})"

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
