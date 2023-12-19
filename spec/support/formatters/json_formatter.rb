# frozen_string_literal: true

require 'rspec/core/formatters'

module Support
  module Formatters
    class JsonFormatter < RSpec::Core::Formatters::JsonFormatter
      QA_SUPPORT_LOGLINKING_CONST = 'QA::Support::Loglinking'

      RSpec::Core::Formatters.register self, :message, :dump_summary, :stop, :seed, :close

      def dump_profile(profile)
        # We don't currently use the profile info. This overrides the base
        # implementation so that it's not included.
      end

      def stop(example_notification)
        # Based on https://github.com/rspec/rspec-core/blob/main/lib/rspec/core/formatters/json_formatter.rb#L35
        # But modified to include full details of multiple exceptions and to provide output similar to
        # https://github.com/sj26/rspec_junit_formatter
        @output_hash[:examples] = example_notification.notifications.map do |notification|
          format_example(notification.example).tap do |hash|
            e = notification.example.exception
            if e
              exceptions = e.respond_to?(:all_exceptions) ? e.all_exceptions : [e]
              hash[:exceptions] = exceptions.map do |exception|
                hash = {
                  class: exception.class.name,
                  message: exception.message
                }

                hash[:backtrace] = notification.formatted_backtrace if notification.respond_to?(:formatted_backtrace)

                if notification.respond_to?(:message_lines)
                  hash[:message_lines] = strip_ansi_codes(notification.message_lines)
                end

                if loglinking
                  hash.merge!(
                    correlation_id: exception.message[match_data_after(loglinking::CORRELATION_ID_TITLE)],
                    sentry_url: exception.message[match_data_after(loglinking::SENTRY_URL_TITLE)],
                    kibana_discover_url: exception.message[match_data_after(loglinking::KIBANA_DISCOVER_URL_TITLE)],
                    kibana_dashboard_url: exception.message[match_data_after(loglinking::KIBANA_DASHBOARD_URL_TITLE)]
                  )
                end

                hash
              end
            end
          end
        end
      end

      private

      def loglinking
        return @loglinking if defined?(@loglinking)

        @loglinking = Object.const_defined?(QA_SUPPORT_LOGLINKING_CONST) &&
          Object.const_get(QA_SUPPORT_LOGLINKING_CONST, false)
      end

      def format_example(example)
        file_path, line_number = location_including_shared_examples(example.metadata)

        {
          id: example.id,
          description: example.description,
          full_description: example.full_description,
          status: example.execution_result.status.to_s,
          file_path: file_path,
          line_number: line_number.to_i,
          run_time: example.execution_result.run_time,
          pending_message: example.execution_result.pending_message,
          testcase: example.metadata[:testcase],
          quarantine: example.metadata[:quarantine],
          screenshot: example.metadata[:screenshot],
          product_group: example.metadata[:product_group],
          feature_category: example.metadata[:feature_category],
          ci_job_url: ENV['CI_JOB_URL'],
          retry_attempts: example.metadata[:retry_attempts],
          level: example.metadata[:level],
          allowed_to_be_slow: example.metadata[:allowed_to_be_slow]
        }
      end

      def location_including_shared_examples(metadata)
        if metadata[:shared_group_inclusion_backtrace].empty?
          [metadata[:file_path], metadata[:line_number]]
        else
          # If there are nested shared examples, the outermost location is last in the array
          (
            metadata[:shared_group_inclusion_backtrace].last.formatted_inclusion_location ||
              # RSpec ignores some paths by default, e.g. bin/, which result in the above being nil.
              # Source: https://github.com/rspec/rspec-core/blob/v3.12.2/lib/rspec/core/backtrace_formatter.rb#L11
              # In that case, we fallback to use the raw `#inclusion_location`.
              metadata[:shared_group_inclusion_backtrace].last.inclusion_location
          ).split(':')
        end
      end

      def strip_ansi_codes(strings)
        # The code below is from https://github.com/piotrmurach/pastel/blob/master/lib/pastel/color.rb
        modified = Array(strings).map { |string| string.dup.gsub(/\x1b\[{1,2}[0-9;:?]*m/m, '') }
        modified.size == 1 ? modified[0] : modified
      end

      def match_data_after(title)
        /(?<=#{title} ).*/
      end
    end
  end
end
