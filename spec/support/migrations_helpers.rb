module MigrationsHelpers
  def table(name)
    Class.new(ActiveRecord::Base) { self.table_name = name }
  end

  def migrations_paths
    ActiveRecord::Migrator.migrations_paths
  end

  def table_exists?(name)
    ActiveRecord::Base.connection.table_exists?(name)
  end

  def migrations
    ActiveRecord::Migrator.migrations(migrations_paths)
  end

  def reset_column_in_migration_models
    ActiveRecord::Base.clear_cache!

    described_class.constants.sort.each do |name|
      const = described_class.const_get(name)

      if const.is_a?(Class) && const < ActiveRecord::Base
        const.reset_column_information
      end
    end
  end

  def previous_migration
    migrations.each_cons(2) do |previous, migration|
      break previous if migration.name == described_class.name
    end
  end

  def migration_schema_version
    self.class.metadata[:schema] || previous_migration.version
  end

  def schema_migrate_down!
    disable_migrations_output do
      ActiveRecord::Migrator.migrate(migrations_paths,
                                     migration_schema_version)
    end

    reset_column_in_migration_models
  end

  def schema_migrate_up!
    disable_migrations_output do
      ActiveRecord::Migrator.migrate(migrations_paths)
    end

    reset_column_in_migration_models
  end

  def disable_migrations_output
    ActiveRecord::Migration.verbose = false

    yield
  ensure
    ActiveRecord::Migration.verbose = true
  end

  def migrate!
    ActiveRecord::Migrator.up(migrations_paths) do |migration|
      migration.name == described_class.name
    end
  end
end
