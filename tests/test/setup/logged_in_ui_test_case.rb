
module Bixby
  module Test
    class LoggedInUITestCase < UITestCase

      def self.before_class
        # login at the start of each class
        self.new.login()
      end

      def self.after_class
        Capybara.current_session.reset!
      end

      def teardown
        # don't reset capybara sessions after each run anymore (by not calling super)
        Capybara.ignore_hidden_elements = true
      end

      # Simply login to the site
      def login
        visit url()
        wait_for_state("login")
        assert has_selector?('button.login')
        fill(
          :username => "pixelcop",
          :password => "test"
        )
        click_button("Login") # case sensitive
        wait_for_state("inventory")
      end

    end
  end
end
