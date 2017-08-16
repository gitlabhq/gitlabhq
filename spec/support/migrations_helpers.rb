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

  def migrate!
    ActiveRecord::Migrator.up(migrations_paths) do |migration|
      migration.name == described_class.name
    end
  end
end
