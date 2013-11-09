
module Micron
  class TestCase
    module Poltergeist

      module ClassMethods
        def after_class
          super
          # clean up after every class is run and force a new poltergeist instance
          Capybara.reset_sessions!
          Capybara.current_session.driver.restart
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def before_setup
        super
        r = Micron.runner.reporters.find{ |r| r.kind_of? Micron::Reporter::Poltergeist }
        page.driver.client.phantomjs_logger = r.logger
      end

      def teardown
        super
        Capybara.reset_sessions!
        Capybara.ignore_hidden_elements = true
      end

    end
  end
end
