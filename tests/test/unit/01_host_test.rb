
require 'helper'
require 'sidekiq'

class Bixby::Integration::Host < Bixby::Test::TestCase

  def test_host_metadata

    # wait for sidekiq to finish, for at most 15 sec
    stats = nil
    timeout(30) {
      while true do
        stats = Sidekiq::Stats.new
        puts stats.processed
        if stats.processed == 2 || stats.failed > 0 ||
            stats.retry_size > 0 then

          break
        end
        sleep 1
      end
    }

    msg = "sidekiq job was successful"
    assert_equal 0, stats.queues["schedules"], msg
    assert_equal 0, stats.retry_size, msg
    assert_equal 0, stats.failed, msg
    assert_equal 2, stats.processed, msg

    hosts = Bixby::Model::Host.list
    assert hosts

    h = hosts.first
    assert h

    md = h["metadata"]
    assert md
    assert_kind_of Array, md

    refute_nil md.find{ |m| m["key"] == "kernel" && m["value"] == "Linux" }
    refute_nil md.find{ |m| m["key"] == "hostname" && m["value"] =~ /bixbytest|test/ }
  end

end

