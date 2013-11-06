
module Bixby
  module Test
    class LoggedInUITestCase < UITestCase

      def teardown
        # don't reset capybara sessions anymore (by not calling super)
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

        # look for navbar inventory tab
        assert has_selector?("div.navbar ul.nav li.inventory.active")
      end

    end
  end
end
