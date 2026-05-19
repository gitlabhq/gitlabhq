# frozen_string_literal: true

# rubocop:disable Gitlab/NoCodeCoverageComment -- see check_parity.rb for explanation
# of :nocov: on rightward assignment lines (SimpleCov #1033).

module AiHarness
  module Doctor
    module Steps
      module PerformDoctorChecks
        class CheckGitignore
          CHECK_NAME = '.gitignore coverage'
          # Keep in sync: if you change these entries, update .ai-harness-doctor-patterns
          # in .gitlab/ci/rules.gitlab-ci.yml so the CI job triggers on the right paths.
          REQUIRED_ENTRIES = %w[CLAUDE.local.md .ai/*].freeze

          # @param context [Hash] the ROP chain context
          # @return [Hash]
          def self.check(context)
            # :nocov:
            context => {
              repo_root: String => repo_root, fix: (TrueClass | FalseClass) => fix, results: Array => results
            }
            # :nocov:

            gitignore_path = File.join(repo_root, '.gitignore')
            missing = find_missing_entries(gitignore_path: gitignore_path)

            if missing.empty?
              results << { name: CHECK_NAME, status: 'OK', details: [] }
            elsif fix
              append_entries(gitignore_path: gitignore_path, entries: missing)
              results << { name: CHECK_NAME, status: 'FIXED', details: missing.map { |e| "Added #{e}" } }
            else
              results << { name: CHECK_NAME, status: 'FAIL', details: missing.map { |e| "Missing: #{e}" } }
            end

            context
          end

          # @param gitignore_path [String]
          # @return [Array<String>]
          def self.find_missing_entries(gitignore_path:)
            return REQUIRED_ENTRIES.dup unless File.exist?(gitignore_path)

            lines = File.readlines(gitignore_path).map(&:strip)

            REQUIRED_ENTRIES.reject { |entry| lines.include?(entry) }
          end

          # @param gitignore_path [String]
          # @param entries [Array<String>]
          # @return [void]
          def self.append_entries(gitignore_path:, entries:)
            content = File.exist?(gitignore_path) ? File.read(gitignore_path) : ''
            content += "\n" unless content.empty? || content.end_with?("\n")
            content += "#{entries.join("\n")}\n"
            File.write(gitignore_path, content)
          end

          private_class_method :find_missing_entries, :append_entries
          private_constant :CHECK_NAME, :REQUIRED_ENTRIES
        end
      end
    end
  end
end
# rubocop:enable Gitlab/NoCodeCoverageComment
