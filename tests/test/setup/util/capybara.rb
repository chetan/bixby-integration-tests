
require "capybara"
require "capybara/poltergeist"
Capybara.default_driver = :poltergeist
Capybara.javascript_driver = :poltergeist
Capybara.default_wait_time = 5

Capybara.register_driver :poltergeist do |app|
  opts = {
    # :logger           => $stdout,
    :phantomjs_logger => $stdout,
  }
  Capybara::Poltergeist::Driver.new(app, opts)
end


class Capybara::Poltergeist::NetworkTraffic::Request
  def completed?
    return false if response_parts.empty?
    response_parts.last.data["stage"] == "end"
  end
end

class Capybara::Poltergeist::NetworkTraffic::Response
  attr_reader :data
end
