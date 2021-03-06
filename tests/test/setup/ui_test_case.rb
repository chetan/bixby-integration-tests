
require "setup/util/capybara"
require "setup/util/netlog_console_filter"
require "setup/util/poltergeist_reporter"
require "setup/util/poltergeist_test_case"

Micron.runner.reporters << Micron::Reporter::Poltergeist.new

module Bixby
  module Test
    class UITestCase < TestCase

      include Capybara::DSL
      include Micron::TestCase::Poltergeist

      def setup
        super
        Capybara.default_wait_time = 10
      end

      def take_screenshot
        temp = Tempfile.new("screenshot-")
        path = temp.path
        temp.close
        temp.unlink

        png = "#{path}.png"
        html = "#{path}.html"

        addr = `ifconfig eth1 | grep 'inet addr' | awk '{print $2}'`
        ip = addr.split(/:/).last.strip

        page.save_screenshot(png, :full => true)
        $stderr.puts "Saved screenshot: http://#{ip}/screenshots/#{File.basename(png)}"

        page.save_page(html)
        $stderr.puts "Saved html to: #{html}" # don't show url because JS just sends us to login page..
      end

      def teardown
        if ENV["USER"] != "travis" then
          # skip on travis, can't use them anyway
          take_screenshot()
        end
        super # do last, so we don't lose our session
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
      #
      # @raise [ExitException] if timeout
      def wait_for_requests(num, sec=10)
        retry_for(sec, "waiting for #{num} network reqs") {
          requests.size >= num && requests.find_all{ |r| r.completed?}.size >= num
        }
      end

      # Wait for the given application state
      #
      # @param [String] state       name of state to wait for
      # @param [Fixnum] sec         How long to wait, in seconds (default: 10)
      #
      # @raise [ExitException] if timeout
      def wait_for_state(state, sec=10)
        retry_for(sec, "waiting for state #{state}") {
          curr_state = evaluate_script("Bixby.app.current_state.name")
          # puts "want state=#{state}; curr_state=#{curr_state}"
          state == curr_state
        }
      end

      # Disable Capybara waits for the given block
      def no_wait(&block)
        Capybara.using_wait_time(0, &block)
      end

      # A version of has_selector? which returns immediately (does not wait for
      # items to appear or disappear)
      #
      # @param [String] selector      to pass to has_selector?
      def has_selector_i?(selector)
        no_wait { has_selector?(selector) }
      end

      def assert_selector(selector)
        assert has_selector?(selector), "Expected selector '#{selector}' to exist within #{Capybara.default_wait_time} sec"
      end

      def assert_selector_i(selector)
        assert has_selector_i?(selector), "Expected selector '#{selector}' to exist (immediately)"
      end

      def refute_selector(selector)
        assert has_no_selector?(selector), "Did not expect selector '#{selector}' to exist after #{Capybara.default_wait_time} sec"
      end

      def refute_selector_i(selector)
        refute has_selector_i?(selector), "Did not expect '#{selector}' to exist"
      end

      # Form fill helper
      #
      # @param [Hash] opts    Keys are selectors and values are form inputs
      def fill(opts={})
        opts.each do |k,v|
          fill_in(k.to_s, :with => v)
        end
      end

    end
  end
end
