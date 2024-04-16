# frozen_string_literal: true

module ClickHouseSchemaHelpers
  def migrate(migration_context, target_version, step = nil)
    quietly { migration_context.up(target_version, step) }
  end

  def rollback(migration_context, target_version, step = 1)
    quietly { migration_context.down(target_version, step) }
  end

  def table_names(database = :main, configuration = ClickHouse::Client.configuration)
    ClickHouse::Client.select('SHOW TABLES', database, configuration).pluck('name')
  end

  def active_schema_migrations_count(database = :main, configuration = ClickHouse::Client.configuration)
    query = <<~SQL
      SELECT COUNT(*) AS count FROM schema_migrations FINAL WHERE active = 1
    SQL

    ClickHouse::Client.select(query, database, configuration).first['count']
  end

  def describe_table(table_name, database = :main, configuration = ClickHouse::Client.configuration)
    ClickHouse::Client
      .select("DESCRIBE TABLE #{table_name} FORMAT JSON", database, configuration)
      .map(&:symbolize_keys)
      .index_by { |h| h[:name].to_sym }
  end

  def schema_migrations(database = :main, configuration = ClickHouse::Client.configuration)
    ClickHouse::Client
      .select('SELECT * FROM schema_migrations FINAL ORDER BY version ASC', database, configuration)
      .map(&:symbolize_keys)
  end

  def clear_db(configuration = ClickHouse::Client.configuration)
    configuration.databases.each_key do |db|
      connection = ::ClickHouse::Connection.new(db, configuration)
      # drop all tables
      lookup_tables(db, configuration).each do |table|
        connection.execute("DROP TABLE IF EXISTS #{table}")
      end

      ClickHouse::MigrationSupport::SchemaMigration.new(connection).ensure_table
    end
  end

  def register_database(config, database_identifier, db_config)
    config.register_database(
      database_identifier,
      database: db_config[:database],
      url: db_config[:url],
      username: db_config[:username],
      password: db_config[:password],
      variables: db_config[:variables] || {}
    )
  end

  private

  def lookup_tables(db, configuration = ClickHouse::Client.configuration)
    ClickHouse::Client.select('SHOW TABLES', db, configuration).pluck('name')
  end

  def quietly(&_block)
    was_verbose = ClickHouse::Migration.verbose
    ClickHouse::Migration.verbose = false

    yield
  ensure
    ClickHouse::Migration.verbose = was_verbose
  end

  def unload_click_house_migration_classes(fixtures_path)
    $LOADED_FEATURES.select { |file| file.include? fixtures_path }.each do |file|
      const = File.basename(file)
                  .scan(ClickHouse::Migration::MIGRATION_FILENAME_REGEXP)[0][1]
                  .camelcase
                  .safe_constantize

      Object.send(:remove_const, const.to_s) if const
      $LOADED_FEATURES.delete(file)
    end
  end
end
