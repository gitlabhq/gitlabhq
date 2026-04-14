# frozen_string_literal: true

require 'open3'

# rubocop:disable Gitlab/NoCodeCoverageComment -- Ruby 3 rightward assignment (`=>`) and
# `case/in` pattern matching generate implicit `:else` branches in Ruby's Coverage API for
# the NoMatchingPatternError path. SimpleCov 0.22 reports these as uncovered with no way to
# suppress them (https://github.com/simplecov-ruby/simplecov/issues/1033). All reachable
# branches are tested; `:nocov:` excludes only the unreachable implicit else paths.

module AiHarness
  module Doctor
    module Steps
      module PerformDoctorChecks
        class CheckParity
          CHECK_NAME = 'CLAUDE.md / AGENTS.md parity'

          # @param context [Hash] the ROP chain context
          # @return [Hash]
          def self.check(context)
            # :nocov:
            context => {
              repo_root: String => repo_root, fix: (TrueClass | FalseClass) => fix, results: Array => results
            }
            # :nocov:

            pairs = find_pairs(repo_root: repo_root)
            issues = validate_pairs(pairs: pairs, repo_root: repo_root)

            if issues.empty?
              results << { name: CHECK_NAME, status: 'OK', details: [] }
            elsif fix
              fix_issues(issues: issues)
              # rubocop:disable Rails/Pluck -- plain Ruby hashes, no ActiveSupport
              results << { name: CHECK_NAME, status: 'FIXED', details: issues.map { |i| i[:detail] } }
            else
              results << { name: CHECK_NAME, status: 'FAIL', details: issues.map { |i| i[:detail] } }
              # rubocop:enable Rails/Pluck
            end

            context
          end

          # @param repo_root [String]
          # @return [Array<Hash>] array of { dir:, agents_path:, claude_path: }
          def self.find_pairs(repo_root:)
            dirs = Set.new

            # Use git ls-files for tracked files (fast on large repos)
            stdout, stderr, status = Open3.capture3(
              'git', '-C', repo_root, 'ls-files', 'AGENTS.md', '**/AGENTS.md', 'CLAUDE.md', '**/CLAUDE.md'
            )
            tracked = stdout.strip
            unless status.success?
              raise "git ls-files failed (exit #{status.exitstatus}): #{stderr.strip} in #{CHECK_NAME}"
            end

            tracked.split("\n").each do |relative_path|
              dirs << File.dirname(File.join(repo_root, relative_path))
            end

            # Also check for untracked files at repo root (common during --fix)
            %w[AGENTS.md CLAUDE.md].each do |name|
              path = File.join(repo_root, name)
              dirs << repo_root if File.exist?(path)
            end

            dirs.map do |dir|
              {
                dir: dir,
                agents_path: File.join(dir, 'AGENTS.md'),
                claude_path: File.join(dir, 'CLAUDE.md')
              }
            end
          end

          # @param pairs [Array<Hash>]
          # @param repo_root [String]
          # @return [Array<Hash>] array of { detail:, agents_path:, claude_path:, action: }
          def self.validate_pairs(pairs:, repo_root:)
            issues = []

            pairs.each do |pair|
              # :nocov:
              pair => { dir: String => dir, agents_path: String => agents_path, claude_path: String => claude_path }
              # :nocov:

              agents_exists = File.exist?(agents_path)
              claude_exists = File.exist?(claude_path)
              prefix = relative_prefix(dir: dir, repo_root: repo_root)

              symlink_issues = detect_symlinks(
                agents_path: agents_path, claude_path: claude_path,
                agents_exists: agents_exists, claude_exists: claude_exists, prefix: prefix
              )

              unless symlink_issues.empty?
                issues.concat(symlink_issues)
                next
              end

              if agents_exists && !claude_exists
                issues << {
                  detail: "#{prefix}CLAUDE.md not found (AGENTS.md exists)",
                  agents_path: agents_path,
                  claude_path: claude_path,
                  action: :copy_agents_to_claude
                }
              elsif claude_exists && !agents_exists
                issues << {
                  detail: "#{prefix}AGENTS.md not found (CLAUDE.md exists)",
                  agents_path: agents_path,
                  claude_path: claude_path,
                  action: :copy_claude_to_agents
                }
              elsif agents_exists && claude_exists && File.read(agents_path) != File.read(claude_path)
                issues << {
                  detail: "#{prefix}CLAUDE.md differs from AGENTS.md",
                  agents_path: agents_path,
                  claude_path: claude_path,
                  action: :copy_agents_to_claude
                }
              end
            end

            issues
          end

          # @param agents_path [String]
          # @param claude_path [String]
          # @param agents_exists [Boolean]
          # @param claude_exists [Boolean]
          # @param prefix [String]
          # @return [Array<Hash>]
          def self.detect_symlinks(agents_path:, claude_path:, agents_exists:, claude_exists:, prefix:)
            issues = []

            if agents_exists && File.symlink?(agents_path)
              issues << {
                detail: "#{prefix}AGENTS.md is a symlink (must be a regular file)",
                agents_path: agents_path,
                claude_path: claude_path,
                action: :replace_agents_symlink
              }
            end

            if claude_exists && File.symlink?(claude_path)
              issues << {
                detail: "#{prefix}CLAUDE.md is a symlink (must be a regular file)",
                agents_path: agents_path,
                claude_path: claude_path,
                action: :replace_claude_symlink
              }
            end

            issues
          end

          # @param issues [Array<Hash>]
          # @return [void]
          def self.fix_issues(issues:)
            issues.each do |issue|
              # :nocov:
              issue => {
                action: Symbol => action,
                agents_path: String => agents_path,
                claude_path: String => claude_path
              }
              # :nocov:

              case action
              when :copy_agents_to_claude then File.write(claude_path, File.read(agents_path))
              when :copy_claude_to_agents then File.write(agents_path, File.read(claude_path))
              when :replace_agents_symlink then replace_symlink(path: agents_path)
              when :replace_claude_symlink then replace_symlink(path: claude_path)
              else raise ArgumentError, "Unknown fix action: #{action}"
              end
            end
          end

          # @param dir [String]
          # @param repo_root [String]
          # @return [String]
          def self.relative_prefix(dir:, repo_root:)
            return '' if dir == repo_root

            relative = dir.delete_prefix("#{repo_root}/")
            "#{relative}/: "
          end

          # @param path [String]
          # @return [void]
          def self.replace_symlink(path:)
            content = File.read(path)
            File.delete(path)
            File.write(path, content)
          end

          private_class_method :find_pairs, :validate_pairs, :fix_issues, :relative_prefix,
            :detect_symlinks, :replace_symlink
          private_constant :CHECK_NAME
        end
      end
    end
  end
end
# rubocop:enable Gitlab/NoCodeCoverageComment
