
require 'helper'

module Bixby
class Integration::UI::StayLoggedIn < Bixby::Test::LoggedInUITestCase

  def test_login_to_site
    login()
  end

  def test_still_logged_in
    visit url()
    wait_for_state("inventory")
    refute  has_selector_i?('button.login')
    assert has_selector?("div.navbar ul.nav li.inventory.active")
  end

  def test_logged_in_across_tests
    wait_for_state("inventory")
    refute  has_selector_i?('button.login')
    assert has_selector?("div.navbar ul.nav li.inventory.active")
  end

  def test_cleanup
    # temp workaround
    Capybara.reset_sessions!
  end

end
end
