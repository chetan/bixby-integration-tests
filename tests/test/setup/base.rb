
require 'bixby-client'
require 'bixby-client/patch/shellout'

require 'timeout'

require 'micron/test_case/redir_logging'
require 'httpi'
require 'mixlib/shellout'
require 'multi_json'

# Logging.logger[HTTPI].level = :info

module Bixby
  module Test
    class TestCase < Micron::TestCase

      include Micron::TestCase::RedirLogging
      @@redir_logger = Logging.logger[Bixby]

      def setup
        ENV["RAILS_ENV"] = "integration"
        ENV["BIXBY_HOME"] = "/opt/bixby"
      end

      def teardown
      end

      def timeout(sec, reason="", &block)
        begin
          Timeout.timeout(sec) {
            yield
          }
        rescue Timeout::Error => ex
          msg = "execution expired (#{sec} sec)"
          msg += ": #{reason}" if not reason.empty?
          raise Micron::Assertion, msg, ex.backtrace
        end
      end

      # Reset agent state, but do not start
      def reset_agent
        shell = systemu("/opt/bixby-integration/scripts/agent/stop.sh")
        assert shell.success?, "agent stopped successfully"
        shell = systemu("/opt/bixby-integration/scripts/agent/reset.sh")
        assert shell.success?, "agent reset successfully"
      end

      # Start the agent daemon (register with the manager)
      def register_agent
        shell = systemu("sudo BIXBY_LOG=debug /opt/bixby/bin/bixby-agent -P test -t pixelcop --tags test -- http://localhost")
        assert shell.success?, "agent started successfully"
        systemu("sudo /etc/init.d/bixby start") # start bixby god
      end

      # Reset the manager state, but do not start
      def reset_manager
        shell = systemu("/opt/bixby-integration/scripts/manager/stop.sh")
        assert shell.success?, "manager stopped successfully"
        shell = systemu("/opt/bixby-integration/scripts/manager/reset.sh")
        assert shell.success?, "manager reset successfully"
      end

      # Start the manager (via god)
      def start_manager
        shell = systemu("sudo RAILS_ENV=integration god -c /var/www/bixby/current/config/deploy/bixby.god")
        assert shell.success?, "manager started successfully"
      end

      # Wait for manager to come up (at most 60 sec)
      #
      # @raise [ExitException] if timeout reached
      def wait_for_manager
        timeout(60) {
          while true do
            sleep 0.5
            return if http_get("http://localhost/").code < 500
          end
        }
      end

      # Wait for a file to exist, for at most limit seconds
      #
      # @param [String] filename
      # @param [Fixnum] limit
      #
      # @return [Boolean] true if file was found within time limit
      # @raise [ExitException] if timeout
      def wait_for_file(filename, limit=5)
        timeout(limit) {
          while true do
            return true if File.exists?(filename)
            sleep 0.25
          end
        }
      end

      # Wait for the given file to change (according to mtime)
      #
      # @param [String] filename
      # @param [Time] start
      # @param [Fixnum] limit
      #
      # @return [Boolean] true if file was changed within time limit
      # @raise [ExitException] if timeout
      def wait_for_file_change(filename, start, limit)
        timeout(limit) {
          while true do
            return true if File.exists?(filename) && File.stat(filename).mtime > start
          end
        }
      end

      # Retry the given block for a maximum number of seconds
      #
      # @param [Fixnum] sec
      # @param [Block] block
      #
      # @raise [ExitException] if timeout
      def retry_for(sec, &block)
        timeout(sec) {
          while true
            sleep 0.1
            return if block.call()
          end
        }
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

    module UI
    end
  end

end # Bixby
