
require 'helper'

module Bixby
class Integration::BasicUI < Bixby::Test::UITestCase

  def test_login_page_loads
    visit url()
    assert page.has_selector?('button.login')
  end

  def test_login_to_site
    visit url()
    assert page.has_selector?('button.login')
    fill_in("username", :with => "pixelcop")
    fill_in("password", :with => "test")

    click_button("Login") # case sensitive

    wait_for_requests(4) # ignore gravatar request for now (external fetch, could take a while..)

    assert page.has_selector?("div.navbar ul.nav li.inventory.active")
  end

end
end
