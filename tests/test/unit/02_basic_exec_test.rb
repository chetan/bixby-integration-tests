
require 'helper'

module Bixby
class Integration::BasicExec < Bixby::Test::AgentTestCase

  def test_hello_world
    cmd = CommandSpec.new({
      :repo    => "vendor",
      :bundle  => "system/general",
      :command => "hello_world.sh",
    })
    cr = remote_exec(cmd)
    assert_equal "hello world\n", cr.stdout
    assert_empty cr.stderr
  end

  def test_get_agent_version

    cmd = CommandSpec.new({
      :repo    => "vendor",
      :bundle  => "system/inventory",
      :command => "get_agent_version.rb",
    })
    cr = remote_exec(cmd)

    ver = File.read(Dir.glob("/opt/bixby/embedded/lib/ruby/gems/*/gems/bixby-agent-*/VERSION").first).strip
    refute_empty ver
    assert_equal ver, cr.stdout.strip
  end

  def test_update_agent_version
    req = JsonRequest.new("inventory:update_version", [@agent_id])
    res = Bixby.client.exec_api(req)
    assert res
    assert res.success?
    assert_equal true, res.data
  end

  def test_list_facts
    cmd = CommandSpec.new({
      :repo    => "vendor",
      :bundle  => "system/inventory",
      :command => "list_facts.rb",
    })
    cr = remote_exec(cmd)
    facts = MultiJson.load(cr.stdout)
    assert_kind_of Hash, facts
    assert_equal "Linux", facts["kernel"]
    assert_equal "bixbytest", facts["hostname"]
  end

end
end
