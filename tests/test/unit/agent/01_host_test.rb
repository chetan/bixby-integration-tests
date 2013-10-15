
require 'helper'

class Bixby::Integration::Agent::Host < Bixby::Test::TestCase

  def test_host_metadata
    hosts = Bixby::Model::Host.list
    assert hosts

    h = hosts.first
    assert h

    md = h["metadata"]
    assert md
    assert_kind_of Array, md

    refute_nil md.find{ |m| m["key"] == "kernel" && m["value"] == "Linux" }
    refute_nil md.find{ |m| m["key"] == "hostname" && m["value"] == "bixbytest" }
  end

end

