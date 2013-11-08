
module Micron
  class Reporter
    class Poltergeist < Console

      attr_reader :logger

      def start_method(method)
        @logger = NetLogConsoleFilter.new
      end

      # Display console.log & network requests after a failure
      def end_method(method)

        return if !method.failed? or method.skipped?

        if not @logger.console.empty? then
          puts indent(underline("console.log:"))
          puts indent(@logger.console.rstrip)
          puts
        end

        if not @logger.netlog.empty? then
          puts indent(underline("network requests:"))
          puts indent(@logger.netlog.rstrip)
          puts
        end

      end


      # stub out all the methods we don't need
      def start_tests(files)
      end

      def start_file(test_file)
      end

      def start_class(clazz)
      end

      def before_class_error(ex)
      end

      def after_class_error(ex)
      end

      def end_class(clazz)
      end

      def end_file(test_file)
      end

      def end_tests(files, results)
      end

    end
  end
end
