# frozen_string_literal: true

# rubocop:disable Gitlab/NoCodeCoverageComment -- see steps/perform_doctor_checks/check_parity.rb
# for explanation of :nocov: on rightward assignment and pattern matching lines (SimpleCov #1033).

require_relative '../../../lib/gitlab/fp/result'
require_relative '../../../lib/gitlab/fp/unmatched_result_error'
require_relative 'messages'
require_relative 'steps/parse_argv'
require_relative 'steps/handle_action'
require_relative 'steps/print_stdout'
require_relative 'steps/print_stderr'

module AiHarness
  module Doctor
    class Main
      # @return [Integer] exit code (0 = success, 1 = failure)
      # @raise [Gitlab::Fp::UnmatchedResultError]
      def self.main
        result =
          Gitlab::Fp::Result.ok({ results: [] })
            .and_then(Steps::ParseArgv.method(:parse))
            .map(Steps::HandleAction.method(:handle))
            .inspect_ok(Steps::PrintStdout.method(:print))
            .inspect_err(Steps::PrintStderr.method(:print))

        # :nocov:
        case result
        in { ok: { exit_code: Integer => code } }
          # :nocov:
          code
        # :nocov:
        in { err: Messages::InvalidArguments => message }
          message.content => { exit_code: Integer => code }
          # :nocov:
          code
        else
          raise Gitlab::Fp::UnmatchedResultError.new(result: result)
        end
      end
    end
  end
end
# rubocop:enable Gitlab/NoCodeCoverageComment
