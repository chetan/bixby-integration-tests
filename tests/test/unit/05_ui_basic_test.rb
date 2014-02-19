
require 'helper'

module Bixby
class Integration::UI::Basic < Bixby::Test::UITestCase

  def test_login_page_loads
    visit url()
    wait_for_state("login")
    assert page.has_selector?('button.login')
  end

  def test_login_to_site
    visit url()
    wait_for_state("login")
    assert page.has_selector?('button.login')
    fill(
      :username => "pixelcop",
      :password => "testtest"
    )

    click_button("Login") # case sensitive
    wait_for_state("inventory")

    # look for navbar inventory tab
    assert has_selector?("nav.navbar ul.nav li.inventory.active"), "user is logged in (navbar visible)"
  end

end
end
