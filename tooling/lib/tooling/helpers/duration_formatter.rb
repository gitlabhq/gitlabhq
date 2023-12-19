# frozen_string_literal: true

module Tooling
  module Helpers
    module DurationFormatter
      def readable_duration(duration_in_seconds)
        minutes = (duration_in_seconds / 60).to_i
        seconds = (duration_in_seconds % 60).round(2)

        min_output = normalize_output(minutes, 'minute')
        sec_output = normalize_output(seconds, 'second')

        "#{min_output} #{sec_output}".strip
      end

      private

      def normalize_output(number, unit)
        if number <= 0
          ""
        elsif number <= 1
          "#{number} #{unit}"
        else
          "#{number} #{unit}s"
        end
      end
    end
  end
end
