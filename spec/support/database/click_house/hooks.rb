# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass
class ClickHouseTestRunner
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

  def clear_db(configuration = ClickHouse::Client.configuration)
    configuration.databases.each_key do |db|
      # drop all tables
      lookup_tables(db, configuration).each do |table|
        ClickHouse::Client.execute("DROP TABLE IF EXISTS #{table}", db, configuration)
      end

      ClickHouse::MigrationSupport::SchemaMigration.create_table(db, configuration)
    end
  end

  def ensure_schema
    return if @ensure_schema

    clear_db

    # run the schema SQL files
    migrations_paths = ClickHouse::MigrationSupport::Migrator.migrations_paths
    schema_migration = ClickHouse::MigrationSupport::SchemaMigration
    migration_context = ClickHouse::MigrationSupport::MigrationContext.new(migrations_paths, schema_migration)
    migration_context.up

    @ensure_schema = true
  end

  private

  def tables_for(db)
    @tables ||= {}
    @tables[db] ||= lookup_tables(db) - [ClickHouse::MigrationSupport::SchemaMigration.table_name]
  end

  def lookup_tables(db, configuration = ClickHouse::Client.configuration)
    ClickHouse::Client.select('SHOW TABLES', db, configuration).pluck('name')
  end
end
# rubocop: enable Gitlab/NamespacedClass

RSpec.configure do |config|
  click_house_test_runner = ClickHouseTestRunner.new

  config.around(:each, :click_house) do |example|
    with_net_connect_allowed do
      was_verbose = ClickHouse::Migration.verbose
      ClickHouse::Migration.verbose = false

      if example.example.metadata[:click_house] == :without_migrations
        click_house_test_runner.clear_db
      else
        click_house_test_runner.ensure_schema
        click_house_test_runner.truncate_tables
      end

      example.run
    ensure
      ClickHouse::Migration.verbose = was_verbose
    end
  end
end
