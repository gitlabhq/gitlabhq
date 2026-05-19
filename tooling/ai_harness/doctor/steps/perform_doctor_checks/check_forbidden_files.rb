# frozen_string_literal: true

require 'open3'

# rubocop:disable Gitlab/NoCodeCoverageComment -- see check_parity.rb for explanation
# of :nocov: on rightward assignment lines (SimpleCov #1033).

module AiHarness
  module Doctor
    module Steps
      module PerformDoctorChecks
        class CheckForbiddenFiles
          CHECK_NAME = 'Forbidden committed files'
          # Keep in sync: if you change these patterns, update .ai-harness-doctor-patterns
          # in .gitlab/ci/rules.gitlab-ci.yml so the CI job triggers on the right paths.
          FORBIDDEN_PATTERNS = %w[
            AGENTS.local.md
            **/AGENTS.local.md
            CLAUDE.local.md
            **/CLAUDE.local.md
            .claude/rules/**
            .claude/skills/**
            .claude/agents/**
            .claude/commands/**
            .claude/settings.json
            .claude/settings.local.json
            .claude/settings.local.jsonc
            .opencode/**
            .gitlab/duo/chat-rules.md
            .gitlab/duo/mcp.json
          ].freeze

          # @param context [Hash] the ROP chain context
          # @return [Hash]
          def self.check(context)
            # :nocov:
            context => { repo_root: String => repo_root, config: Hash => config, results: Array => results }
            # :nocov:

            allowed_prefixes = config.fetch('allowed_committed_files')
            found = find_tracked_forbidden_files(repo_root: repo_root, allowed_prefixes: allowed_prefixes)

            if found.empty?
              results << { name: CHECK_NAME, status: 'OK', details: [] }
            else
              details = found.map { |f| "Forbidden file tracked by git: #{f}" }
              results << { name: CHECK_NAME, status: 'FAIL', details: details }
            end

            context
          end

          # @param repo_root [String]
          # @param allowed_prefixes [Array<String>]
          # @return [Array<String>]
          def self.find_tracked_forbidden_files(repo_root:, allowed_prefixes:)
            stdout, stderr, status = Open3.capture3(
              'git', '-C', repo_root, 'ls-files', *FORBIDDEN_PATTERNS
            )
            output = stdout.strip
            unless status.success?
              raise "git ls-files failed (exit #{status.exitstatus}): #{stderr.strip} in #{CHECK_NAME}"
            end

            output.split("\n").reject(&:empty?).reject do |f|
              allowed_prefixes.any? { |prefix| f.start_with?(prefix) }
            end
          end

          private_class_method :find_tracked_forbidden_files
          private_constant :CHECK_NAME, :FORBIDDEN_PATTERNS
        end
      end
    end
  end
end
# rubocop:enable Gitlab/NoCodeCoverageComment
