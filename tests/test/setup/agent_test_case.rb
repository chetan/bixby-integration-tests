
module Bixby
  module Test
    class AgentTestCase < TestCase

      def setup
        super
        @agent = Bixby::Model::Agent.list.first
        @agent_id = @agent["id"]
      end

      # Execute the given CommandSpec on the agent and do basic validation
      # for a successful response
      #
      # @param [CommandSpec] cmd      to execute on agent
      def remote_exec(cmd)
        req = JsonRequest.new("remote_exec:exec", [@agent_id, cmd])
        res = Bixby.client.exec_api(req)
        assert res
        assert_kind_of JsonResponse, res
        assert res.success?

        cr = CommandResponse.from_json_response(res)
        assert cr
        assert cr.success?, "remote exec should succeed"
        cr
      end

    end
  end
end
