# frozen_string_literal: true

require 'open3'

module AiHarness
  module Doctor
    module Steps
      module PerformDoctorChecks
        class ResolveRepoRoot
          # @param context [Hash] the ROP chain context
          # @return [Hash]
          def self.resolve(context)
            stdout, stderr, status = Open3.capture3('git', 'rev-parse', '--show-toplevel')
            root = stdout.chomp
            raise "git rev-parse failed (exit #{status.exitstatus}): #{stderr.strip}" unless status.success?

            if root.empty?
              raise "Failed to determine git repo root. " \
                "Ensure 'git' is installed and you are inside a git repository."
            end

            context[:repo_root] = root
            context
          end
        end
      end
    end
  end
end
