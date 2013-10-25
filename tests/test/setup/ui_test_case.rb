
require "capybara"
require "capybara/poltergeist"
Capybara.default_driver = :poltergeist
Capybara.javascript_driver = :poltergeist
Capybara.default_wait_time = 5



class Capybara::Poltergeist::NetworkTraffic::Request
  def completed?
    return false if response_parts.empty?
    response_parts.last.data["stage"] == "end"
  end
end

class Capybara::Poltergeist::NetworkTraffic::Response
  attr_reader :data
end

module Bixby
  module Test
    class UITestCase < TestCase

      include Capybara::DSL

      def setup
        super
      end

      def teardown
        super
        Capybara.reset_sessions!
        Capybara.use_default_driver
      end

      # Create a URL to the given path
      #
      # @param [String] path
      #
      # @return [String] url to path
      def url(path="")
        return URI.join("http://localhost/", path).to_s
      end

      # Helper to retrieve network requests
      def requests
        page.driver.network_traffic
      end

      # Wait for the given number of network requests to complete
      #
      # @param [Fixnum] num               Number of requests to wait for
      # @param [Fixnum] sec               How long to wait
      def wait_for_requests(num, sec=10)
        retry_for(sec) {
          requests.size >= num && requests.find_all{ |r| r.completed?}.size >= num
        }
      end

    end
  end
end
