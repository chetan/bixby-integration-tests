
require 'helper'

module Bixby
class Integration::Agent::BasicExec < Bixby::Test::TestCase

  def setup
    super
    @agent = Bixby::Model::Agent.list.first
    @agent_id = @agent["id"]
  end

  # Execute the given CommandSpec on the agent and do basic validation
  # for a successful response
  #
  # @param [CommandSpec] cmd      to execute on agent
  def exec(cmd)
    req = JsonRequest.new("remote_exec:exec", [@agent_id, cmd])
    res = Bixby.client.exec_api(req)
    assert res
    assert_kind_of JsonResponse, res
    assert res.success?

    cr = CommandResponse.from_json_response(res)
    assert cr
    assert cr.success?
    cr
  end

  def test_hello_world

    # tell the manager to execute hello world
    cmd = CommandSpec.new({
      :repo    => "vendor",
      :bundle  => "system/general",
      :command => "hello_world.sh",
    })
    cr = exec(cmd)
    assert_equal "hello world\n", cr.stdout
    assert_empty cr.stderr
  end

end
end
