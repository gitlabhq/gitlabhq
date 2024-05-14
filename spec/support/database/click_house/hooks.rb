# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass
class ClickHouseTestRunner
  include ClickHouseSchemaHelpers

  def truncate_tables
    ClickHouse::Client.configuration.databases.each_key do |db|
      # Select tables with at least one row
      query = tables_for(db).map do |table|
        "(SELECT '#{table}' AS table FROM #{table} LIMIT 1)"
      end.join(' UNION ALL ')

      next if query.empty?

      tables_with_data = ClickHouse::Client.select(query, db).pluck('table')
      tables_with_data.each do |table|
        ClickHouse::Client.execute("TRUNCATE TABLE #{table}", db)
      end
    end
  end

  def ensure_schema
    return if @ensure_schema

    clear_db

    # run the schema SQL files
    migrations_paths = ClickHouse::MigrationSupport::Migrator.migrations_paths(:main)
    connection = ::ClickHouse::Connection.new(:main)
    schema_migration = ClickHouse::MigrationSupport::SchemaMigration.new(connection)
    schema_migration.ensure_table
    migration_context = ClickHouse::MigrationSupport::MigrationContext.new(connection,
      migrations_paths, schema_migration)
    Gitlab::ExclusiveLease.skipping_transaction_check { migrate(migration_context, nil) }

    @ensure_schema = true
  end

  def reset_schema_cache!
    @ensure_schema = nil
  end

  private

  def tables_for(db)
    @tables ||= {}
    @tables[db] ||= lookup_tables(db) - %w[schema_migrations]
  end
end
# rubocop: enable Gitlab/NamespacedClass

RSpec.configure do |config|
  click_house_test_runner = ClickHouseTestRunner.new

  config.around(:each, :click_house) do |example|
    with_net_connect_allowed do
      if example.example.metadata[:click_house] == :without_migrations
        click_house_test_runner.clear_db
        click_house_test_runner.reset_schema_cache!
      else
        click_house_test_runner.ensure_schema
        click_house_test_runner.truncate_tables
      end

      example.run
    end
  end
end
