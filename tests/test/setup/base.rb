
require 'micron/test_case/redir_logging'

module Bixby
  module Test
    class TestCase < Micron::TestCase

      include Micron::TestCase::RedirLogging
      @@redir_logger = Logging.logger[Bixby]

      def setup
      end

      def teardown
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
