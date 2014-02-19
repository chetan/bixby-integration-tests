
require 'helper'

module Bixby
class Integration::UI::StayLoggedIn < Bixby::Test::LoggedInUITestCase

  def test_still_logged_in
    visit url()
    wait_for_state("inventory")
    refute  has_selector_i?('button.login')
    assert has_selector?("nav.navbar ul.nav li.inventory.active"), "user is logged in (navbar visible)"
  end

  def test_logged_in_across_tests
    wait_for_state("inventory")
    refute  has_selector_i?('button.login')
    assert has_selector?("nav.navbar ul.nav li.inventory.active"), "user is logged in (navbar visible)"
  end

end
end
