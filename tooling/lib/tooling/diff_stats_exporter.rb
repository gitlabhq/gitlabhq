# frozen_string_literal: true

require "logger"
require "open3"
require "time"
require "gitlab_quality/test_tooling/click_house/client"

module Tooling
  class DiffStatsExporter
    REQUIRED_ENV_VARS = %w[
      GLCI_DA_CLICKHOUSE_URL
      GLCI_CLICKHOUSE_METRICS_USERNAME
      GLCI_CLICKHOUSE_METRICS_PASSWORD
      GLCI_CLICKHOUSE_WORK_ITEM_DB
      GLCI_DIFF_STATS_CLICKHOUSE_TABLE
      CI_COMMIT_SHA
      CI_PIPELINE_ID
      CI_PROJECT_ID
      CI_PROJECT_PATH
      CI_MERGE_REQUEST_IID
      CI_MERGE_REQUEST_DIFF_BASE_SHA
    ].freeze

    GIT_STATUS_MAP = {
      "A" => "added",
      "M" => "modified",
      "D" => "deleted",
      "R" => "renamed",
      "C" => "copied"
    }.freeze

    GIT_LOG_FORMAT = "%s|||%an|||%ae|||%cI"

    def initialize(log_level: :info)
      @logger = Logger.new($stdout, level: log_level).tap do |l|
        l.formatter = proc do |severity, _datetime, _progname, msg|
          "[DiffStatsExporter] #{severity}: #{msg}\n"
        end
      end
    end

    def execute
      unless environment_variables_set?
        missing = REQUIRED_ENV_VARS.reject { |var| ENV[var] && !ENV[var].empty? }
        logger.error("Missing required env vars: #{missing.join(', ')}")
        return false
      end

      logger.info("Exporting diff stats for pipeline #{ENV['CI_PIPELINE_ID']}")

      row = build_row
      clickhouse_client.insert_json_data(ENV["GLCI_DIFF_STATS_CLICKHOUSE_TABLE"], [row])
      logger.info("Successfully exported diff stats to ClickHouse (#{row[:total_files_changed]} files changed)")
      true
    rescue StandardError => e
      logger.error("Failed to export diff stats: #{e.message}")
      logger.error(e.backtrace.join("\n")) if e.backtrace
      false
    end

    private

    attr_reader :logger

    def build_row
      fetch_base_sha
      numstat = parse_numstat
      name_status = parse_name_status
      changed_files = merge_diff_data(numstat, name_status)
      commit_metadata = parse_commit_metadata

      {
        commit_sha: ENV["CI_COMMIT_SHA"],
        project_id: ENV["CI_PROJECT_ID"].to_i,
        project_path: ENV["CI_PROJECT_PATH"],
        pipeline_id: ENV["CI_PIPELINE_ID"].to_i,
        mr_iid: ENV["CI_MERGE_REQUEST_IID"].to_i,
        ref: ENV["CI_COMMIT_REF_NAME"].to_s,
        message: commit_metadata[:message],
        author_name: commit_metadata[:author_name],
        author_email: commit_metadata[:author_email],
        committed_at: commit_metadata[:committed_at],
        changed_files: changed_files,
        total_lines_added: changed_files.sum { |f| f[:lines_added] },
        total_lines_deleted: changed_files.sum { |f| f[:lines_deleted] },
        total_files_changed: changed_files.size,
        received_at: Time.now.utc.strftime("%Y-%m-%d %H:%M:%S.%6N"),
        gitlab_instance: ENV.fetch("CI_SERVER_HOST", "gitlab.com")
      }
    end

    def source_sha
      if ENV['CI_MERGE_REQUEST_EVENT_TYPE'] == 'merged_result'
        ENV['CI_MERGE_REQUEST_SOURCE_BRANCH_SHA']
      else
        ENV['CI_COMMIT_SHA']
      end
    end

    def base_sha
      ENV['CI_MERGE_REQUEST_DIFF_BASE_SHA']
    end

    # Two-dot diff: compares trees directly without needing connected commit history.
    # This works with shallow clones where base_sha is fetched with --depth=1.
    # Three-dot diff (A...B) would fail with "no merge base" in that scenario.
    def diff_range
      "#{base_sha}..#{source_sha}"
    end

    def fetch_base_sha
      out, status = Open3.capture2e("git", "fetch", "origin", base_sha, "--depth=1")
      raise "git fetch failed: #{out}" unless status.success?
    end

    def parse_numstat
      out, status = Open3.capture2e("git", "diff", "--numstat", diff_range)
      raise "git diff --numstat failed: #{out}" unless status.success?

      out.lines.filter_map do |line|
        parts = line.chomp.split("\t")
        next if parts.size < 3

        additions, deletions, path = parts
        next if additions == "-" # binary file

        { path: path, lines_added: additions.to_i, lines_deleted: deletions.to_i }
      end
    end

    def parse_name_status
      out, status = Open3.capture2e("git", "diff", "--name-status", diff_range)
      raise "git diff --name-status failed: #{out}" unless status.success?

      out.lines.each_with_object({}) do |line, hash|
        parts = line.chomp.split("\t")
        next if parts.empty?

        raw_status = parts[0]
        path = parts.size >= 3 ? parts[2] : parts[1] # for renames/copies, parts[2] is the destination path
        # Normalize status code (e.g. R100 -> R)
        status_code = raw_status[0]

        hash[path] = GIT_STATUS_MAP.fetch(status_code, "modified")
      end
    end

    def merge_diff_data(numstat, name_status)
      numstat.map do |entry|
        path = entry[:path]
        {
          path: path,
          change_type: name_status.fetch(path, "modified"),
          file_extension: File.extname(path),
          lines_added: entry[:lines_added],
          lines_deleted: entry[:lines_deleted]
        }
      end
    end

    def parse_commit_metadata
      out, status = Open3.capture2e("git", "log", "-1", source_sha, "--format=#{GIT_LOG_FORMAT}")
      raise "git log failed: #{out}" unless status.success?

      message, author_name, author_email, committed_at = out.chomp.split("|||")

      {
        message: message.to_s,
        author_name: author_name.to_s,
        author_email: author_email.to_s,
        committed_at: committed_at.to_s
      }
    end

    def environment_variables_set?
      REQUIRED_ENV_VARS.all? { |var| ENV[var] && !ENV[var].empty? }
    end

    def clickhouse_client
      @clickhouse_client ||= ::GitlabQuality::TestTooling::ClickHouse::Client.new(
        url: ENV["GLCI_DA_CLICKHOUSE_URL"],
        database: ENV["GLCI_CLICKHOUSE_WORK_ITEM_DB"],
        username: ENV["GLCI_CLICKHOUSE_METRICS_USERNAME"],
        password: ENV["GLCI_CLICKHOUSE_METRICS_PASSWORD"],
        logger: logger
      )
    end
  end
end
