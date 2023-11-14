# frozen_string_literal: true

module Capybara
  MESSAGE = <<~MSG
    Timeout (%{timeout}s) reached while running a waiting Capybara finder.
    Consider using a non-waiting finder.

    See https://www.cloudbees.com/blog/faster-rails-tests
  MSG

  module Node
    class Base
      # Inspired by https://github.com/ngauthier/capybara-slow_finder_errors
      module SlowFinder
        def synchronize(seconds = nil, errors: nil)
          start_time = ::Gitlab::Metrics::System.monotonic_time

          super
        rescue Capybara::ElementNotFound => e
          seconds ||= Capybara.default_max_wait_time

          raise e unless seconds > 0 && ::Gitlab::Metrics::System.monotonic_time - start_time > seconds

          message = format(MESSAGE, timeout: seconds)
          raise e, "#{$!}\n\n#{message}", e.backtrace
        end
      end

      prepend SlowFinder
    end
  end
end
