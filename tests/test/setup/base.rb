
require 'bixby-client'
require 'bixby-client/patch/shellout'

require 'httpi'
require 'micron/test_case/redir_logging'
require 'mixlib/shellout'
require 'multi_json'

# Logging.logger[HTTPI].level = :info

module Bixby
  module Test
    class TestCase < Micron::TestCase

      include Micron::TestCase::RedirLogging
      @@redir_logger = Logging.logger[Bixby]

      def setup
        ENV["BIXBY_HOME"] = "/opt/bixby"
      end

      def teardown
      end

      def reset_agent
        shell = systemu("/opt/bixby-integration/scripts/agent/stop.sh")
        assert shell.success?, "agent reset successfully"
      end

      def register_agent
        shell = systemu("sudo /opt/bixby/bin/bixby-agent -P test -t pixelcop -- http://localhost")
        assert shell.success?, "agent started successfully"
      end

      def reset_manager
        shell = systemu("/opt/bixby-integration/scripts/manager/stop.sh")
        assert shell.success?, "manager stopped successfully"
        shell = systemu("/opt/bixby-integration/scripts/manager/reset.sh")
        assert shell.success?, "manager reset successfully"
      end

      def start_manager
        shell = systemu("sudo RAILS_ENV=staging god -c /var/www/bixby/current/config/deploy/bixby.god")
        assert shell.success?, "manager started successfully"
      end

      def wait_for_manager
        while true do
          sleep 0.5
          return if http_get("http://localhost/").code < 500
        end
      end


      # HTTP Helpers
      def http_get(url)
        HTTPI.get(url)
      end



      # String dump helper for debugging
      def dump(str)
        begin
          if str[0] == "{" then
            h = MultiJson.load(str)
            ap h
            if h["errors"] then
              h["errors"].each{ |e| puts e }
            end
            puts "---"
            return
          end
        rescue Exception => ex
        end

        puts str
        puts "---"
      end

      # Run command and log output before returning
      def systemu(*args)

        # Cleanup the ENV and execute
        old_env = {}
        %W{BUNDLE_BIN_PATH BUNDLE_GEMFILE}.each{ |r|
          old_env[r] = ENV.delete(r) if ENV.include?(r) }

        cmd = Mixlib::ShellOut.new(*args)
        cmd.run_command

        # return if not debug?
        puts "cmd: #{args.join(' ')}"
        puts "status: #{cmd.exitstatus}"
        puts "stdout:"
        dump cmd.stdout
        puts "stderr:"
        dump cmd.stderr


        old_env.each{ |k,v| ENV[k] = v } # reset the ENV

        cmd
      end

    end # TestCase
  end # Test

  module Integration
    module Agent
    end

    module Manager
    end

    module Repo
    end
  end

end # Bixby
