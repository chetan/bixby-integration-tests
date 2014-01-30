
module Bixby
  module Test
    class LoggedInUITestCase < UITestCase

      def self.before_class
        # login at the start of each class
        self.new.login()
      end

      def teardown
        # don't reset capybara sessions after each run anymore (by not calling super)
        Capybara.ignore_hidden_elements = true
      end

      # Simply login to the site
      def login

        # disable logging in for this step so we don't spew to stdout (since before_class methods aren't captured)
        # out = $stdout
        # page.driver.client.phantomjs_logger = out
        page.driver.client.phantomjs_logger = NetLogConsoleFilter.new

        visit url()
        wait_for_state("login")
        assert has_selector?('button.login')
        fill(
          :username => "pixelcop",
          :password => "testtest"
        )
        click_button("Login") # case sensitive
        wait_for_state("inventory")
      end

    end
  end
end
