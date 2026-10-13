# frozen_string_literal: true

module Tooling
  module PredictiveTests
    # Picks the rspec files that loaded any of the changed source files, using the ClickHouse coverage map.
    # Returns no specs and a reason when the change can't be judged from the map, so the caller runs the full suite.
    class FileBasedSelector
      Result = Struct.new(:specs, :full_suite_reason, keyword_init: true)

      SOURCE_FILE_REGEX = %r{\A(ee/)?(app|lib)/.+\.rb\z}
      SPEC_FILE_REGEX = %r{\A(ee/)?spec/.+_spec\.rb\z}
      # Frontend code, jest specs and docs. The Vue 3 migration specs read two kinds of these files, so keep them.
      IGNORED_FILE_REGEX = %r{
        \A(?!.*(?:vue3_migration\.yml|/pages/.+/index\.js)\z)
        (?:.*\.(?:vue|js|mjs|ts|scss|css|md)\z|(?:ee/)?app/assets/)
      }x
      # ClickHouse rejects queries over 256 KiB, so long path lists are queried in batches.
      BATCH_SIZE = 1_000
      # Capture runs about every 2 hours, so 6 hours without a new row means it has stalled.
      MAX_MAP_AGE_SECONDS = 6 * 60 * 60
      # Past this many specs changed since the last capture, the map is too far behind to trust.
      MAX_RECENT_SPECS = 500

      # `recent_changed_files` are the files changed on master since the map's last capture, or nil when unknown.
      def initialize(
        changed_files:, clickhouse_client:, project_path:, recent_changed_files: [],
        file_exists: File.method(:exist?)
      )
        @changed_files = changed_files
        @recent_changed_files = recent_changed_files
        @clickhouse_client = clickhouse_client
        @project_path = project_path
        @file_exists = file_exists
      end

      def execute
        relevant = changed_files.reject { |file| IGNORED_FILE_REGEX.match?(file) }
        sources, others = relevant.partition { |file| SOURCE_FILE_REGEX.match?(file) }
        own_specs, others = others.partition { |file| SPEC_FILE_REGEX.match?(file) }

        return full_suite("files the map can't judge: #{others.sort.join(', ')}") if others.any?

        return full_suite("can't tell what changed since the last capture") if sources.any? && recent_changed_files.nil?

        age = map_age_seconds if sources.any?
        return full_suite("map is stale: newest capture is #{age / 3600} hours old") if age && age > MAX_MAP_AGE_SECONDS

        specs_by_source = specs_for(sources)
        unmapped = sources - specs_by_source.keys
        return full_suite("no map rows for: #{unmapped.sort.join(', ')}") if unmapped.any?

        recent_specs = recent_changes(sources)
        if recent_specs.size > MAX_RECENT_SPECS
          return full_suite("#{recent_specs.size} specs changed since the last capture")
        end

        # Specs changed on master after the capture have no map rows yet.
        specs = specs_by_source.values.flatten + own_specs + recent_specs
        Result.new(specs: specs.uniq.select { |spec| @file_exists.call(spec) }.sort, full_suite_reason: nil)
      end

      private

      attr_reader :changed_files, :clickhouse_client, :project_path, :recent_changed_files

      def recent_changes(sources)
        return [] if sources.empty?

        recent_changed_files.grep(SPEC_FILE_REGEX)
      end

      def full_suite(reason)
        Result.new(specs: [], full_suite_reason: reason)
      end

      def map_age_seconds
        sql = <<~SQL
          SELECT dateDiff('second', max(timestamp), now()) AS age FROM code_coverage.test_coverage_per_file
          WHERE ci_project_path = '#{escape(project_path)}' AND test_file NOT LIKE 'qa/%'
        SQL

        clickhouse_client.query(sql, format: 'JSONEachRow').dig(0, 'age').to_i
      end

      def specs_for(sources)
        sources.each_slice(BATCH_SIZE).each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |batch, memo|
          query(batch).each { |row| memo[row['source_file']] << row['test_file'] }
        end
      end

      def query(sources)
        list = sources.map { |file| "'#{escape(file)}'" }.join(', ')
        sql = <<~SQL
          SELECT DISTINCT source_file, test_file FROM code_coverage.test_files_by_source_file FINAL
          WHERE ci_project_path = '#{escape(project_path)}'
            AND source_file IN (#{list})
            AND test_file NOT LIKE 'qa/%'
            AND test_file LIKE '%_spec.rb'
        SQL

        clickhouse_client.query(sql, format: 'JSONEachRow')
      end

      def escape(value)
        value.to_s.gsub("'", "''")
      end
    end
  end
end
