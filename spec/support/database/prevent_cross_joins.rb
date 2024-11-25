# frozen_string_literal: true

# This module tries to discover and prevent cross-joins across tables
# This will forbid usage of tables of different gitlab_schemas
# on a same query unless explicitly allowed by. This will change execution
# from a given point to allow cross-joins. The state will be cleared
# on a next test run.
#
# This method should be used to mark METHOD introducing cross-join
# not a test using the cross-join.
#
# class User
#   def ci_owned_runners
#     ::Gitlab::Database.allow_cross_joins_across_databases(url: link-to-issue-url)
#
#     ...
#   end
# end

module Database
  module PreventCrossJoins
    CrossJoinAcrossUnsupportedTablesError = Class.new(StandardError)

    ALLOW_THREAD_KEY = :allow_cross_joins_across_databases
    ALLOW_ANNOTATE_KEY = ALLOW_THREAD_KEY.to_s.freeze

    def self.validate_cross_joins!(sql)
      return if Thread.current[ALLOW_THREAD_KEY] || sql.include?(ALLOW_ANNOTATE_KEY)

      # Allow spec/support/database_cleaner.rb queries to disable/enable triggers for many tables
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/339396
      return if sql.include?("DISABLE TRIGGER") || sql.include?("ENABLE TRIGGER")

      tables = begin
        PgQuery.parse(sql).tables
      rescue PgQuery::ParseError
        # PgQuery might fail in some cases due to limited nesting:
        # https://github.com/pganalyze/pg_query/issues/209
        return
      end

      schemas = ::Gitlab::Database::GitlabSchema.table_schemas!(tables)

      unless ::Gitlab::Database::GitlabSchema.cross_joins_allowed?(schemas, tables)
        Thread.current[:has_cross_join_exception] = true
        raise CrossJoinAcrossUnsupportedTablesError,
          "Unsupported cross-join across '#{tables.join(', ')}' querying '#{schemas.to_a.join(', ')}' discovered " \
          "when executing query '#{sql}'. Please refer to https://docs.gitlab.com/ee/development/database/multiple_databases.html#removing-joins-between-ci_-and-non-ci_-tables for details on how to resolve this exception."
      end
    end

    module SpecHelpers
      def with_cross_joins_prevented
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |event|
          ::Database::PreventCrossJoins.validate_cross_joins!(event.payload[:sql])
        end

        Thread.current[ALLOW_THREAD_KEY] = false

        yield
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
      end

      def allow_cross_joins_across_databases(url:, &block)
        ::Gitlab::Database.allow_cross_joins_across_databases(url: url, &block)
      end
    end

    module GitlabDatabaseMixin
      def allow_cross_joins_across_databases(url:)
        old_value = Thread.current[ALLOW_THREAD_KEY]
        Thread.current[ALLOW_THREAD_KEY] = true

        yield
      ensure
        Thread.current[ALLOW_THREAD_KEY] = old_value
      end
    end

    module ActiveRecordRelationMixin
      def allow_cross_joins_across_databases(url:)
        super.annotate(ALLOW_ANNOTATE_KEY)
      end
    end
  end
end

Gitlab::Database.singleton_class.prepend(
  Database::PreventCrossJoins::GitlabDatabaseMixin)

ActiveRecord::Relation.prepend(
  Database::PreventCrossJoins::ActiveRecordRelationMixin)

ALLOW_LIST = Set.new(YAML.load_file(File.join(__dir__, 'cross-join-allowlist.yml'))).freeze

RSpec.configure do |config|
  config.include(::Database::PreventCrossJoins::SpecHelpers)

  config.around do |example|
    Thread.current[:has_cross_join_exception] = false

    if ALLOW_LIST.include?(example.file_path_rerun_argument)
      example.run
    else
      with_cross_joins_prevented { example.run }
    end
  end
end
