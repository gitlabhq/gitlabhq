# frozen_string_literal: true

module AutoExplain
  class << self
    def setup
      Gitlab::Database::EachDatabase.each_connection do |connection|
        next unless record_auto_explain?(connection)

        connection.execute("LOAD 'auto_explain'")

        # This param can only be set on pg14+ so we can't set it when starting postgres.
        connection.execute('ALTER SYSTEM SET compute_query_id TO on')
        connection.execute('SELECT pg_reload_conf()')
      end
    end

    def record
      Gitlab::Database::EachDatabase.each_connection do |connection, connection_name|
        next unless record_auto_explain?(connection)

        connection.execute(<<~SQL.squish)
          CREATE EXTENSION IF NOT EXISTS file_fdw;
          CREATE SERVER IF NOT EXISTS pglog FOREIGN DATA WRAPPER file_fdw;
        SQL

        csvlog_columns = [
          'log_time timestamp(3) with time zone',
          'user_name text',
          'database_name text',
          'process_id integer',
          'connection_from text',
          'session_id text',
          'session_line_num bigint',
          'command_tag text',
          'session_start_time timestamp with time zone',
          'virtual_transaction_id text',
          'transaction_id bigint',
          'error_severity text',
          'sql_state_code text',
          'message text',
          'detail text',
          'hint text',
          'internal_query text',
          'internal_query_pos integer',
          'context text',
          'query text',
          'query_pos integer',
          'location text',
          'application_name text',
          'backend_type text',
          'leader_pid integer',
          'query_id bigint'
        ]

        connection.transaction do
          connection.execute(<<~SQL.squish)
            CREATE FOREIGN TABLE IF NOT EXISTS pglog (#{csvlog_columns.join(', ')})
            SERVER pglog
            OPTIONS ( filename 'log/pglog.csv', format 'csv' );
          SQL

          log_file = Rails.root.join(
            File.dirname(ENV.fetch('RSPEC_AUTO_EXPLAIN_LOG_PATH', 'auto_explain/auto_explain.ndjson.gz')),
            "#{ENV.fetch('CI_JOB_NAME_SLUG', 'rspec')}.#{Process.pid}.#{connection_name}.ndjson.gz"
          )

          FileUtils.mkdir_p(File.dirname(log_file))

          fingerprints = Set.new
          recording_start = Time.now

          Zlib::GzipWriter.open(log_file) do |gz|
            pg = connection.raw_connection

            pg.exec('SET statement_timeout TO 0;')

            pg.send_query(<<~SQL.squish)
              SELECT DISTINCT ON (m.query_id)
                  m.message->>'Query Text' as query, m.message->'Plan' as plan
              FROM (
              SELECT substring(message from '\{.*$')::jsonb AS message, query_id
              FROM pglog
              WHERE message LIKE '%{%'
              ) m
              ORDER BY m.query_id;
            SQL

            pg.set_single_row_mode
            pg.get_result.stream_each do |row|
              query = row['query']
              fingerprint = PgQuery.fingerprint(query)
              next unless fingerprints.add?(fingerprint)

              plan = Gitlab::Json.parse(row['plan'])

              output = {
                query: query,
                plan: plan,
                fingerprint: fingerprint,
                normalized: PgQuery.normalize(query)
              }

              gz.puts Gitlab::Json.generate(output)
            end

            puts "auto_explain log contains #{fingerprints.size} entries for #{connection_name}, writing to #{log_file}"
            puts "took #{Time.now - recording_start}"
          end

          raise ActiveRecord::Rollback
        end
      end
    end

    private

    def record_auto_explain?(connection)
      return false unless ENV['CI']
      return false if ENV['CI_JOB_NAME_SLUG'] == 'db-migrate-non-superuser'
      return false if connection.database_version.to_s[0..1].to_i < 14
      return false if connection.select_one('SHOW is_superuser')['is_superuser'] != 'on'
      return false if connection.select_one('SELECT pg_stat_file(\'log/pglog.csv\', true)')['pg_stat_file'].nil?

      # This condition matches the pipeline rules for if-merge-request
      return true if %w[detached merged_result].include?(ENV['CI_MERGE_REQUEST_EVENT_TYPE'])

      # This condition matches the pipeline rules for if-default-branch-refs
      ENV['CI_COMMIT_REF_NAME'] == ENV['CI_DEFAULT_BRANCH'] && !ENV['CI_MERGE_REQUEST_IID']
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    AutoExplain.setup
  end

  config.after(:suite) do
    AutoExplain.record
  end
end
