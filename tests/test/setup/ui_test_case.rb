
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

class ConsoleFilter

  def initialize(real_out, filter=true)
    @real_out = real_out
    @filter = filter
    @buffer = StringIO.new
  end

  def write(data)

    if !@filter then
      @real_out.write(data)
      return
    end

    # get previous buffer (partial line)
    b = @buffer.read
    @buffer.rewind
    if not b.empty? then
      data = b + data
    end

    # read lines from data
    buff = StringIO.new(data)
    lines = buff.readlines
    if lines then
      if lines.last !~ /\n$/ then
        # store partial lines for next write
        @buffer.write(lines.pop)
      end
      lines.each{ |line|
        if line =~ /^\[netlog\]/ then
          @real_out.puts(line)
        end
      }
    end

  end
end

module Bixby
  module Test
    class UITestCase < TestCase

      include Capybara::DSL

      def setup
        super
        # make sure the logger gets updated to the correct object on each test run
        # since Micron will replace $stdout/$stderr before each method is run
        console_filter = ConsoleFilter.new($stdout, true)
        page.driver.client.phantomjs_logger = console_filter if page.driver.client.phantomjs_logger
        page.driver.browser.logger = out if page.driver.browser.logger
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
      #
      # @raise [ExitException] if timeout
      def wait_for_requests(num, sec=10)
        retry_for(sec) {
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
        retry_for(sec) {
          state == evaluate_script("Bixby.app.current_state.name")
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
