# frozen_string_literal: true

require 'open3'

module Tooling
  module PredictiveTests
    # The git side of file-based selection: this MR's files, and what changed on master since the map's last capture.
    class GitChanges
      def initialize(base_sha:, clickhouse_client:, project_path:, git: method(:run_git))
        @base_sha = base_sha
        @clickhouse_client = clickhouse_client
        @project_path = project_path
        @git = git
      end

      def mr_files
        ensure_commit(base_sha)
        git.call('diff', '--name-only', '--no-renames', base_sha, 'HEAD').split("\n")
      end

      # Files changed on master since the map's last capture. Nil when that can't be worked out.
      def since_last_capture
        captured_sha = last_captured_sha
        return if captured_sha.empty?

        puts "Last capture: #{captured_sha}"
        ensure_commit(captured_sha)
        # A capture newer than the MR base already includes what the MR branched from.
        captured_at, base_at = [captured_sha, base_sha].map { |sha| git.call('show', '-s', '--format=%ct', sha).to_i }
        return [] if captured_at >= base_at

        changed = git.call('diff', '--name-only', '--diff-filter=ACMR', "#{captured_sha}..#{base_sha}").split("\n")
        puts "#{changed.size} files changed on master since the last capture"
        changed
      rescue StandardError => e
        puts "Could not compare with the last capture: #{e.message}"
        nil
      end

      private

      attr_reader :base_sha, :clickhouse_client, :project_path, :git

      # Same query as `last_capture_sha` in scripts/per_test_coverage/select_tests.rb; keep in sync.
      def last_captured_sha
        rows = clickhouse_client.query(<<~SQL, format: 'JSONEachRow')
          SELECT argMax(captured_sha, timestamp) AS sha FROM code_coverage.test_coverage_per_file FINAL
          WHERE ci_project_path = '#{project_path.gsub("'", "''")}'
            AND captured_sha != '' AND test_file NOT LIKE 'qa/%'
        SQL

        rows.dig(0, 'sha').to_s
      end

      # The CI clone is shallow, so a commit may be missing. One commit is enough to compare two trees.
      def ensure_commit(sha)
        git.call('cat-file', '-e', "#{sha}^{commit}")
      rescue StandardError
        git.call('fetch', '--depth=1', 'origin', sha)
      end

      def run_git(*args)
        out, err, status = Open3.capture3('git', *args)
        raise "git #{args.join(' ')} failed: #{err}" unless status.success?

        out
      end
    end
  end
end
