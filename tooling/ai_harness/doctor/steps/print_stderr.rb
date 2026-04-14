# frozen_string_literal: true

# rubocop:disable Gitlab/NoCodeCoverageComment -- see perform_doctor_checks/check_parity.rb for
# explanation of :nocov: on rightward assignment lines (SimpleCov #1033).

module AiHarness
  module Doctor
    module Steps
      class PrintStderr
        # @param message [Gitlab::Fp::Message] the err message
        # @return [void]
        def self.print(message)
          # :nocov:
          message.content => { stderr_text: String => output }
          # :nocov:
          $stderr.print(output) # rubocop:disable Gitlab/DirectStdio -- CLI script, must write to stderr
          nil
        end
      end
    end
  end
end
# rubocop:enable Gitlab/NoCodeCoverageComment
