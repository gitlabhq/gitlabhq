# frozen_string_literal: true

# This module tries to discover and prevent cross-joins across tables
# This will forbid usage of tables between CI and main database
# on a same query unless explicitly allowed by. This will change execution
# from a given point to allow cross-joins. The state will be cleared
# on a next test run.
#
# This method should be used to mark METHOD introducing cross-join
# not a test using the cross-join.
#
# class User
#   def ci_owned_runners
#     ::Gitlab::Database.allow_cross_joins_across_databases!(url: link-to-issue-url)
#
#     ...
#   end
# end

module Database
  module PreventCrossJoins
    CrossJoinAcrossUnsupportedTablesError = Class.new(StandardError)

    def self.validate_cross_joins!(sql)
      return if Thread.current[:allow_cross_joins_across_databases]

      # PgQuery might fail in some cases due to limited nesting:
      # https://github.com/pganalyze/pg_query/issues/209
      tables = PgQuery.parse(sql).tables

      unless only_ci_or_only_main?(tables)
        raise CrossJoinAcrossUnsupportedTablesError,
          "Unsupported cross-join across '#{tables.join(", ")}' discovered " \
          "when executing query '#{sql}'"
      end
    end

    # Returns true if a set includes only CI tables, or includes only non-CI tables
    def self.only_ci_or_only_main?(tables)
      tables.all? { |table| CiTables.include?(table) } ||
        tables.none? { |table| CiTables.include?(table) }
    end

    module SpecHelpers
      def with_cross_joins_prevented
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |event|
          ::Database::PreventCrossJoins.validate_cross_joins!(event.payload[:sql])
        end

        Thread.current[:allow_cross_joins_across_databases] = false

        yield
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
      end
    end

    module GitlabDatabaseMixin
      def allow_cross_joins_across_databases(url:)
        Thread.current[:allow_cross_joins_across_databases] = true
        super
      end
    end
  end
end

Gitlab::Database.singleton_class.prepend(
  Database::PreventCrossJoins::GitlabDatabaseMixin)

RSpec.configure do |config|
  config.include(::Database::PreventCrossJoins::SpecHelpers)

  # TODO: remove `:prevent_cross_joins` to enable the check by default
  config.around(:each, :prevent_cross_joins) do |example|
    with_cross_joins_prevented { example.run }
  end
end
