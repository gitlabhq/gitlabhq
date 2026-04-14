# frozen_string_literal: true

# rubocop:disable Gitlab/NoCodeCoverageComment -- see check_parity.rb for explanation
# of :nocov: on rightward assignment lines (SimpleCov #1033).

module AiHarness
  module Doctor
    module Steps
      module PerformDoctorChecks
        class FormatOutput
          # @param context [Hash] the ROP chain context
          # @return [Hash]
          def self.format(context)
            # :nocov:
            context => { results: Array => results }
            # :nocov:

            lines = results.map do |result|
              # :nocov:
              result => { name: String => name, status: String => status, details: Array => details }
              # :nocov:

              line = "Check: #{name} #{dots_for(name)} #{status}"
              detail_lines = details.map { |d| "  #{d}" }
              ([line] + detail_lines).join("\n")
            end

            context[:stdout_text] = "#{lines.join("\n")}\n"
            context
          end

          DOT_TARGET_WIDTH = 50
          private_constant :DOT_TARGET_WIDTH

          # @param name [String]
          # @return [String]
          def self.dots_for(name)
            dot_count = [DOT_TARGET_WIDTH - name.length, 3].max
            '.' * dot_count
          end

          private_class_method :dots_for
        end
      end
    end
  end
end
# rubocop:enable Gitlab/NoCodeCoverageComment
