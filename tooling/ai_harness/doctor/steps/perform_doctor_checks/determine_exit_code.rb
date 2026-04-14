# frozen_string_literal: true

# rubocop:disable Gitlab/NoCodeCoverageComment -- see check_parity.rb for explanation
# of :nocov: on rightward assignment lines (SimpleCov #1033).

module AiHarness
  module Doctor
    module Steps
      module PerformDoctorChecks
        class DetermineExitCode
          # @param context [Hash] the ROP chain context
          # @return [Hash]
          def self.determine(context)
            # :nocov:
            context => { results: Array => results }
            # :nocov:

            context[:exit_code] = results.any? { |r| r.fetch(:status) == 'FAIL' } ? 1 : 0
            context
          end
        end
      end
    end
  end
end
# rubocop:enable Gitlab/NoCodeCoverageComment
