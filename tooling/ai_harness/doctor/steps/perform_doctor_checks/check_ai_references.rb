# frozen_string_literal: true

require 'open3'

# rubocop:disable Gitlab/NoCodeCoverageComment -- see check_parity.rb for explanation
# of :nocov: on rightward assignment lines (SimpleCov #1033).

module AiHarness
  module Doctor
    module Steps
      module PerformDoctorChecks
        class CheckAiReferences
          CHECK_NAME = '.ai/ reference resolution'
          # Keep in sync: if you change this pattern, update .ai-harness-doctor-patterns
          # in .gitlab/ci/rules.gitlab-ci.yml so the CI job triggers on the right paths.
          AI_REF_PATTERN = %r{\.ai/[\w.\-/]+\w}

          # @param context [Hash] the ROP chain context
          # @return [Hash]
          def self.check(context)
            # :nocov:
            context => { repo_root: String => repo_root, results: Array => results }
            # :nocov:

            missing = find_missing_references(repo_root: repo_root)

            if missing.empty?
              results << { name: CHECK_NAME, status: 'OK', details: [] }
            else
              details = missing.map { |ref| "#{ref} does not exist" }
              results << { name: CHECK_NAME, status: 'FAIL', details: details }
            end

            context
          end

          # @param repo_root [String]
          # @return [Array<String>] missing reference paths
          def self.find_missing_references(repo_root:)
            references = []

            # Keep in sync: if you change these patterns, update .ai-harness-doctor-patterns
            # in .gitlab/ci/rules.gitlab-ci.yml so the CI job triggers on the right paths.
            stdout, stderr, status = Open3.capture3(
              'git', '-C', repo_root, 'ls-files', 'AGENTS.md', '**/AGENTS.md'
            )
            output = stdout.strip
            unless status.success?
              raise "git ls-files failed (exit #{status.exitstatus}): #{stderr.strip} in #{CHECK_NAME}"
            end

            agents_files = output.split("\n").reject(&:empty?)

            # Also check untracked root AGENTS.md (common during initial setup or --fix).
            # Only the root is special-cased for untracked file scanning because subdirectory
            # AGENTS.md files should be tracked via `git add --force` before they need checking.
            root_agents = File.join(repo_root, 'AGENTS.md')
            # rubocop:disable Rails/NegateInclude -- standalone script, no ActiveSupport available
            agents_files << 'AGENTS.md' if File.exist?(root_agents) && !agents_files.include?('AGENTS.md')
            # rubocop:enable Rails/NegateInclude

            agents_files.uniq.each do |relative_path|
              full_path = File.join(repo_root, relative_path)
              next unless File.exist?(full_path)

              agents_dir = File.dirname(full_path)
              relative_dir = File.dirname(relative_path)
              content = File.read(full_path)
              content.scan(AI_REF_PATTERN).each do |ref|
                ref_path = File.join(agents_dir, ref)
                display_ref = relative_dir == '.' ? ref : File.join(relative_dir, ref)
                references << display_ref unless File.exist?(ref_path)
              end
            end

            references.uniq
          end

          private_class_method :find_missing_references
          private_constant :CHECK_NAME, :AI_REF_PATTERN
        end
      end
    end
  end
end
# rubocop:enable Gitlab/NoCodeCoverageComment
