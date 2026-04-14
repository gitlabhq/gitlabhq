# frozen_string_literal: true

# rubocop:disable Gitlab/NoCodeCoverageComment -- see perform_doctor_checks/check_parity.rb for
# explanation of :nocov: on rightward assignment lines (SimpleCov #1033).

require_relative 'help_text'
require_relative 'perform_doctor_checks/main'

module AiHarness
  module Doctor
    module Steps
      class HandleAction
        # @param context [Hash] the ROP chain context
        # @return [Hash]
        def self.handle(context)
          # :nocov:
          context => { print_help: (TrueClass | FalseClass) => print_help }
          # :nocov:

          if print_help
            context[:stdout_text] = HelpText.help
            context[:exit_code] = 0
            context
          else
            PerformDoctorChecks::Main.main(context)
          end
        end
      end
    end
  end
end
# rubocop:enable Gitlab/NoCodeCoverageComment
