# frozen_string_literal: true

require_relative '../../../../../lib/gitlab/fp/result'
require_relative 'resolve_repo_root'
require_relative 'load_config'
require_relative 'check_parity'
require_relative 'check_ai_references'
require_relative 'check_gitignore'
require_relative 'check_forbidden_files'
require_relative 'format_output'
require_relative 'determine_exit_code'

module AiHarness
  module Doctor
    module Steps
      module PerformDoctorChecks
        class Main
          # @param context [Hash] the parent context
          # @return [Hash]
          def self.main(context)
            result =
              Gitlab::Fp::Result.ok(context)
                .map(ResolveRepoRoot.method(:resolve))
                .map(LoadConfig.method(:load))
                .map(CheckParity.method(:check))
                .map(CheckAiReferences.method(:check))
                .map(CheckGitignore.method(:check))
                .map(CheckForbiddenFiles.method(:check))
                .map(FormatOutput.method(:format))
                .map(DetermineExitCode.method(:determine))

            result.unwrap
          end
        end
      end
    end
  end
end
