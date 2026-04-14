# frozen_string_literal: true

module AiHarness
  module Doctor
    module Steps
      class HelpText
        # @return [String]
        def self.help
          <<~HELP
            Usage: scripts/ai_harness/doctor [OPTIONS]

            Validates AI agent instruction files in the GitLab monorepo.

            Options:
              --fix   Auto-repair fixable problems
              --help  Print this help text and exit
          HELP
        end
      end
    end
  end
end
