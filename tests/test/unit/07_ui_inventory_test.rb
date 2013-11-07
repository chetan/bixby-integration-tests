
require 'helper'

module Bixby
class Integration::UI::Inventory < Bixby::Test::LoggedInUITestCase

  def test_login_to_site
    login()
  end

  def test_approve_host

    host = Bixby::Model::Host.find(1)
    assert host

    # add 'new' tag if doesn't exist (helpful for re-running this test)
    if !host.tags.split(/,/).include? "new" then
      Bixby::Model::Host.update(1, {:tags => "test,new"})
      host = Bixby::Model::Host.find(1)
      assert_includes host.tags.split(/,/), "new", "should now include #new tag"
    end

    visit url()
    wait_for_state("inventory")

    Capybara.ignore_hidden_elements = false

    # approve/reject buttons not visible until we hover
    refute find("div.new_host_list button.approve").visible?
    refute find("div.new_host_list button.reject").visible?

    find("div.new_host_list div.body").hover
    assert find("div.new_host_list button.approve").visible?
    assert find("div.new_host_list button.reject").visible?

    # approve it and see if table re-renders
    click_button("approve")

    assert find("div.host_list ul.tags a.tag").visible? # should now appear
    assert_equal "#test", find("div.host_list ul.tags a.tag").text
    refute has_selector_i?("div.new_host_list button.approve")
  end

  def test_has_monitoring_link
    assert_selector_i "div.host_list div.host div.actions a.monitoring"
  end

  def test_view_host_data
    find("div.host_list a.host").click
    wait_for_state("inv_view_host")

    # now on host page
    assert_equal "Facts", page.all("div.host h4").first.text.strip
    assert_selector_i "div.metadata table.metadata"

    metadata = read_host_metadata()
    assert metadata
    refute_empty metadata
    assert_equal "amd64", metadata["architecture"]
    assert metadata["uptime_seconds"].to_i > 0
  end

  def test_refresh_host_metadata
    assert_selector_i "div.metadata table.metadata"
    old_metadata = read_host_metadata()
    old_uptime = old_metadata["uptime_seconds"].to_i

    assert_selector_i "div.host button.refresh-facts"

    # click refresh: spinner should appear then disappear after some seconds
    find("div.host button.refresh-facts").click
    assert_selector "div.host button.refresh-facts div.spinner"
    refute_selector "div.host button.refresh-facts div.spinner"

    # uptime should have increased
    new_metadata = read_host_metadata()
    new_uptime = new_metadata["uptime_seconds"].to_i
    assert new_uptime
    refute_equal old_uptime, new_uptime
    assert new_uptime > old_uptime
  end

  def test_edit_host_data

    refute_selector_i "div.host button.edit"
    find("div.host div.body").hover
    assert_selector_i "div.host button.edit"

    click_button("edit")
    assert_selector "div.host_editor"

    i = Random.rand(1000)
    fill(
      :Alias       => "hostalias-#{i}",
      :Description => "hostdesc-#{i}"
    )

    # enter new tag
    page.execute_script('$("li.select2-search-field").mousedown()')
    page.execute_script("$('input.select2-input').val('hosttag-#{i},')")
    page.execute_script("$('input.select2-input').trigger('keyup-change')")
    retry_for(1) {
      # wait for list to get updated
      2 == page.all("ul.select2-choices li.select2-search-choice").size
    }

    click_button("Save")
    refute_selector "div.host_editor" # should disappear

    # verify data got updated on backend
    host = nil
    retry_for(3) {
      host = Bixby::Model::Host.find(1)
      "hostalias-#{i}" == host[:alias]
    }
    assert_equal "hostalias-#{i}", host[:alias]
    assert_equal "hostdesc-#{i}", host[:desc]

    tags = host[:tags].split(/,/)
    assert_includes tags, "test"
    assert_includes tags, "hosttag-#{i}"

    # verify in UI
    assert page.find("h3").text =~ /hostalias-#{i}/
    assert page.find("blockquote.desc").text =~ /hostdesc-#{i}/
    assert page.all("a.tag").first.text == "#hosttag-#{i}"
  end


  private


  def read_host_metadata
    ret = {}
    page.all("div.metadata table.metadata tr").each do |el|
      k = el["title"] || el["data-original-title"]
      next if k.nil?
      ret[k] = el["data-content"]
    end
    ret
  end

end
end
