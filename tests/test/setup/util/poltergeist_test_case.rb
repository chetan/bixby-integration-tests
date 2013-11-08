
module Micron
  class TestCase
    module Poltergeist

      def before_setup
        super
        r = Micron.runner.reporters.find{ |r| r.kind_of? Micron::Reporter::Poltergeist }
        page.driver.client.phantomjs_logger = r.logger
      end

      def self.after_class
        Capybara.reset_sessions!
      end

      def teardown
        super
        Capybara.reset_sessions!
        Capybara.ignore_hidden_elements = true
      end

    end
  end
end
