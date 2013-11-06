
require 'helper'

module Bixby
class Integration::BasicUI < Bixby::Test::UITestCase

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
      :password => "test"
    )

    click_button("Login") # case sensitive
    wait_for_state("inventory")

    # look for navbar inventory tab
    assert page.has_selector?("div.navbar ul.nav li.inventory.active")
  end

end
end
